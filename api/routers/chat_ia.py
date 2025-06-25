import os
import requests
import uuid
import json
import re
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Dict, Any

from config import SessionLocal
from models.estado_psicologico import EstadoPsicologico
from models.historial_chat import HistorialChat
from models.tareas import Tarea
from dotenv import load_dotenv

load_dotenv()
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"

router = APIRouter()

# ------------------ DB DEPENDENCY ------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ------------------ HELPERS ------------------
def obtener_ultimo_estado_psicologico(db: Session, usuario_id: str):
    return db.query(EstadoPsicologico)\
        .filter_by(usuario_id=usuario_id)\
        .order_by(EstadoPsicologico.fecha.desc())\
        .first()

def obtener_historial_chat(db: Session, usuario_id: str, limite=10):
    return db.query(HistorialChat)\
        .filter_by(usuario_id=usuario_id)\
        .order_by(HistorialChat.fecha.desc())\
        .limit(limite)\
        .all()[::-1]  # orden cronológico

def extraer_bloque_tareas(contenido: str) -> list:
    match = re.search(r'Bloque de tareas sugeridas:\s*(\[[\s\S]+?\])', contenido)
    if match:
        try:
            return json.loads(match.group(1))
        except:
            return []
    return []

# ------------------ RUTA PRINCIPAL ------------------
@router.post("/chat/ia")
async def conversar_con_ia(payload: Dict[str, Any], db: Session = Depends(get_db)):
    usuario_id = payload.get("usuario_id")
    mensaje_usuario = payload.get("mensaje")

    if not usuario_id or not mensaje_usuario:
        raise HTTPException(status_code=400, detail="usuario_id y mensaje son requeridos.")

    estado = obtener_ultimo_estado_psicologico(db, usuario_id)
    historial = obtener_historial_chat(db, usuario_id)
    historial_texto = "\n".join([
        f"Usuario: {h.mensaje_usuario}\nIA: {h.respuesta_ia}"
        for h in historial
    ])

    # Construir prompt base
    prompt_base = f"""
Actúa como un asistente terapéutico especializado en salud mental y bienestar emocional. Estás interactuando con un usuario que atraviesa un proceso de recuperación emocional. Tu propósito exclusivo es brindar apoyo conversacional empático, sin realizar diagnósticos clínicos ni emitir juicios.

⚠️ IMPORTANTE: Tu función está estrictamente limitada al contexto de salud mental. No puedes brindar información, consejos ni ayuda en temas que no sean emocionales o relacionados al bienestar personal.

📌 Temas estrictamente prohibidos (no debes responder sobre esto):
- Programación, código, desarrollo de software o IA
- Matemáticas, física o ciencia académica
- Ayuda en tareas, trabajos, exámenes o solución de ejercicios
- Historia, cultura general, geografía, idiomas o biología
- Tecnología, juegos, política o economía
- Opiniones sobre productos, gustos, películas o arte
- Religión, creencias personales o filosofía

⚠️ Si el usuario realiza una pregunta fuera del contexto emocional o busca ayuda en tareas, responde exclusivamente con una frase como alguna de las siguientes (elige la más adecuada):
1. "Mi función es acompañarte emocionalmente. ¿Quieres contarme cómo te has sentido últimamente?"
2. "Estoy aquí para escucharte y ayudarte en tu proceso emocional, ¿quieres que hablemos de cómo estás hoy?"
3. "Puedo ayudarte a entender lo que sientes o apoyarte si estás pasando por algo difícil. ¿Te gustaría que hablemos sobre eso?"
4. "No puedo ayudarte con ese tema, pero estoy aquí para hablar contigo sobre lo que sientes y cómo te afecta."
5. "Mi propósito no es resolver ejercicios ni responder preguntas técnicas, pero puedo escucharte si necesitas desahogarte."

📜 Historial de conversación reciente:
{historial_texto}

Usuario: {mensaje_usuario}
"""

    # Añadir información del estado si existe
    if estado:
        prompt = prompt_base + f"""

📋 Estado emocional del usuario:
Nivel: {estado.nivel}
Descripción: {estado.descripcion}

💡 Si consideras que es útil, incluye al final de tu respuesta un bloque con tareas sugeridas para el usuario en el siguiente formato JSON:
Bloque de tareas sugeridas:
[
  {{
    "titulo": "...",
    "descripcion": "...",
    "prioridad": "alta|media|baja"
  }},
  ...
]
"""
    else:
        prompt = prompt_base + """

⚠️ IMPORTANTE: El usuario aún no ha completado su evaluación emocional inicial. 
Responde de manera empática y útil, pero al final de tu respuesta, de manera amigable y sin ser insistente, sugiérele que complete la evaluación emocional para poder brindarle un apoyo más personalizado y efectivo.

Ejemplo de sugerencia: "Por cierto, para poder brindarte un apoyo más personalizado, te recomiendo completar la evaluación emocional cuando tengas un momento. Esto me ayudará a entender mejor cómo te sientes y ofrecerte sugerencias más específicas para tu bienestar."
"""

    try:
        response = requests.post(
            DEEPSEEK_API_URL,
            headers={"Authorization": f"Bearer {DEEPSEEK_API_KEY}"},
            json={
                "model": "deepseek-chat",
                "messages": [
                    {"role": "system", "content": "Eres un asistente terapéutico de salud mental."},
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.6,
                "max_tokens": 700
            }
        )

        response.raise_for_status()
        data = response.json()
        contenido_ia = data["choices"][0]["message"]["content"]

        # Guardar historial
        nuevo_chat = HistorialChat(
            id=str(uuid.uuid4()),
            usuario_id=usuario_id,
            mensaje_usuario=mensaje_usuario,
            respuesta_ia=contenido_ia,
            fecha=datetime.utcnow()
        )
        db.add(nuevo_chat)

        # Detectar y guardar tareas solo si el usuario tiene estado psicológico
        tareas = []
        if estado:
            tareas = extraer_bloque_tareas(contenido_ia)
            for t in tareas:
                tarea = Tarea(
                    id=str(uuid.uuid4()),
                    usuario_id=usuario_id,
                    titulo=t.get("titulo", "Sin título")[:100],
                    descripcion=t.get("descripcion"),
                    prioridad=t.get("prioridad", "media"),
                    origen="ia",
                    fecha_creacion=datetime.utcnow(),
                    fecha_actualizacion=datetime.utcnow(),
                    sincronizada=False,
                    completada=False
                )
                db.add(tarea)

        db.commit()

        return {"respuesta": contenido_ia, "tareas_generadas": tareas}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chat/ia/historial/{usuario_id}")
def obtener_historial_chat_usuario(usuario_id: str, db: Session = Depends(get_db)):
    historial = obtener_historial_chat(db, usuario_id)
    return [
        {
            "mensaje_usuario": h.mensaje_usuario,
            "respuesta_ia": h.respuesta_ia,
            "fecha": h.fecha.isoformat()
        } for h in historial
    ]