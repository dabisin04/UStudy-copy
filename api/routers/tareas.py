import uuid
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional

from config import SessionLocal
from models.tareas import Tarea
from pydantic import BaseModel, Field, validator
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

# ------------------ DB DEPENDENCY ------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ------------------ SCHEMAS ------------------
class TareaCreate(BaseModel):
    usuario_id: str
    titulo: str = Field(..., min_length=1, max_length=100)
    descripcion: Optional[str] = None
    prioridad: Optional[str] = "media"
    fecha_recordatorio: Optional[datetime] = None
    origen: Optional[str] = "usuario"

    @validator('prioridad')
    def validar_prioridad(cls, value):
        if value not in ["alta", "media", "baja"]:
            raise ValueError("prioridad debe ser 'alta', 'media' o 'baja'")
        return value

    @validator('origen')
    def validar_origen(cls, value):
        if value not in ["usuario", "ia"]:
            raise ValueError("origen debe ser 'usuario' o 'ia'")
        return value

class TareaUpdate(BaseModel):
    titulo: Optional[str] = Field(None, min_length=1, max_length=100)
    descripcion: Optional[str]
    prioridad: Optional[str]
    fecha_recordatorio: Optional[datetime]
    completada: Optional[bool]
    sincronizada: Optional[bool]

    @validator('prioridad')
    def validar_prioridad(cls, value):
        if value and value not in ["alta", "media", "baja"]:
            raise ValueError("prioridad debe ser 'alta', 'media' o 'baja'")
        return value

# ------------------ RUTAS CRUD ------------------

# GET todas las tareas de un usuario
@router.get("/tareas/{usuario_id}", response_model=List[dict])
def obtener_tareas(usuario_id: str, db: Session = Depends(get_db)):
    if not usuario_id:
        raise HTTPException(status_code=400, detail="El usuario_id es requerido.")
    tareas = db.query(Tarea).filter_by(usuario_id=usuario_id).order_by(Tarea.fecha_creacion.desc()).all()
    return [t.__dict__ for t in tareas]

# POST crear nueva tarea
@router.post("/tareas", response_model=dict)
def crear_tarea(data: TareaCreate, db: Session = Depends(get_db)):
    if not data.usuario_id:
        raise HTTPException(status_code=400, detail="usuario_id es obligatorio.")
    nueva_tarea = Tarea(
        id=str(uuid.uuid4()),
        usuario_id=data.usuario_id,
        titulo=data.titulo[:100],
        descripcion=data.descripcion,
        prioridad=data.prioridad,
        fecha_recordatorio=data.fecha_recordatorio,
        origen=data.origen,
        completada=False,
        sincronizada=False,
        fecha_creacion=datetime.utcnow(),
        fecha_actualizacion=datetime.utcnow()
    )
    db.add(nueva_tarea)
    db.commit()
    return nueva_tarea.__dict__

# PATCH actualizar parcialmente una tarea
@router.patch("/tareas/{tarea_id}", response_model=dict)
def actualizar_tarea(tarea_id: str, data: TareaUpdate, db: Session = Depends(get_db)):
    tarea = db.query(Tarea).filter_by(id=tarea_id).first()
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada.")

    campos_actualizables = data.dict(exclude_unset=True)
    if not campos_actualizables:
        raise HTTPException(status_code=400, detail="No se proporcionaron campos para actualizar.")

    for campo, valor in campos_actualizables.items():
        setattr(tarea, campo, valor)

    tarea.fecha_actualizacion = datetime.utcnow()
    db.commit()
    return tarea.__dict__

# DELETE eliminar tarea
@router.delete("/tareas/{tarea_id}")
def eliminar_tarea(tarea_id: str, db: Session = Depends(get_db)):
    tarea = db.query(Tarea).filter_by(id=tarea_id).first()
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada.")
    db.delete(tarea)
    db.commit()
    return {"mensaje": "Tarea eliminada correctamente."}

# GET una tarea por ID
@router.get("/tarea/{tarea_id}", response_model=dict)
def obtener_tarea_por_id(tarea_id: str, db: Session = Depends(get_db)):
    tarea = db.query(Tarea).filter_by(id=tarea_id).first()
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada.")
    return tarea.__dict__

# GET tareas completadas o no completadas de un usuario
@router.get("/tareas/{usuario_id}/completadas", response_model=List[dict])
def obtener_tareas_completadas(usuario_id: str, completadas: bool, db: Session = Depends(get_db)):
    tareas = db.query(Tarea)\
        .filter_by(usuario_id=usuario_id, completada=completadas)\
        .order_by(Tarea.fecha_creacion.desc())\
        .all()
    return [t.__dict__ for t in tareas]

# POST marcar tarea como completada o no
@router.post("/tareas/{tarea_id}/completar", response_model=dict)
def marcar_tarea_completada(tarea_id: str, completada: bool = True, db: Session = Depends(get_db)):
    tarea = db.query(Tarea).filter_by(id=tarea_id).first()
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada.")

    tarea.completada = completada
    tarea.fecha_actualizacion = datetime.utcnow()
    db.commit()
    return tarea.__dict__

# GET tareas por prioridad y/o origen
@router.get("/tareas/{usuario_id}/filtrar", response_model=List[dict])
def filtrar_tareas(
    usuario_id: str,
    prioridad: Optional[str] = None,
    origen: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Tarea).filter_by(usuario_id=usuario_id)
    if prioridad:
        query = query.filter_by(prioridad=prioridad)
    if origen:
        query = query.filter_by(origen=origen)
    tareas = query.order_by(Tarea.fecha_creacion.desc()).all()
    return [t.__dict__ for t in tareas]

# POST sincronización masiva de tareas (desde cliente)
@router.post("/tareas/sync", response_model=dict)
def sincronizar_tareas(payload: List[dict], db: Session = Depends(get_db)):
    if not isinstance(payload, list) or not payload:
        raise HTTPException(status_code=400, detail="Se requiere una lista de tareas para sincronizar.")

    resultados = {"creadas": 0, "actualizadas": 0}

    for t in payload:
        if "id" not in t:
            continue

        tarea = db.query(Tarea).filter_by(id=t["id"]).first()
        if tarea:
            # actualizar campos existentes
            for campo in [
                "titulo", "descripcion", "prioridad", "completada",
                "fecha_recordatorio", "sincronizada", "origen"
            ]:
                if campo in t:
                    setattr(tarea, campo, t[campo])
            tarea.fecha_actualizacion = datetime.utcnow()
            resultados["actualizadas"] += 1
        else:
            nueva = Tarea(
                id=t["id"],
                usuario_id=t["usuario_id"],
                titulo=t.get("titulo", "Sin título")[:100],
                descripcion=t.get("descripcion"),
                prioridad=t.get("prioridad", "media"),
                completada=t.get("completada", False),
                sincronizada=True,
                origen=t.get("origen", "usuario"),
                fecha_recordatorio=t.get("fecha_recordatorio"),
                fecha_creacion=datetime.utcnow(),
                fecha_actualizacion=datetime.utcnow()
            )
            db.add(nueva)
            resultados["creadas"] += 1

    db.commit()
    return {
        "mensaje": "Sincronización completa.",
        "resultado": resultados
    }

