import os
import openai
import uuid
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel
from typing import List, Dict, Any

from config import SessionLocal
from models.estado_psicologico import EstadoPsicologico
from dotenv import load_dotenv

load_dotenv()

openai.api_key = os.getenv("DEEPSEEK_API_KEY")

router = APIRouter()

# ------------------ DB DEPENDENCY ------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ------------------ REQUEST SCHEMA ------------------
class RespuestaItem(BaseModel):
    pregunta: str
    valor_respuesta: int

class RespuestaFormulario(BaseModel):
    usuario_id: str
    respuestas: List[RespuestaItem]

    class Config:
        extra = "forbid"

# ------------------ PROMPT TEMPLATE ------------------
def construir_prompt(respuestas: List[RespuestaItem]) -> str:
    respuestas_texto = "\n".join(
        [f"- {r.pregunta} → {r.valor_respuesta}" for r in respuestas]
    )

    prompt = f"""
Actúa como un psicólogo clínico especializado en bienestar emocional.

A continuación se presentan las respuestas de un usuario a un cuestionario estructurado en 4 dimensiones: ánimo (depresión), ansiedad, estrés y apoyo emocional. Cada pregunta tiene una respuesta entre 0 (nunca) y 3 (siempre).

Analiza las respuestas y realiza lo siguiente:

1. Calcula el promedio por dimensión (depresión, ansiedad, estrés y apoyo).
2. Estima el estado psicológico general del usuario según el siguiente sistema de niveles:
   - verde: usuario estable y emocionalmente bien
   - amarillo_claro: señales leves de afectación emocional
   - amarillo: síntomas moderados que requieren atención
   - naranja: signos graves que requieren acciones urgentes
   - rojo: síntomas críticos, posible riesgo emocional

3. Genera una descripción empática y profesional del estado del usuario.
4. Sugiere al menos 3 recomendaciones prácticas para su bienestar emocional.

Formato de salida:
{{
  "nivel": "amarillo",
  "calificaciones": {{
    "animo": 2.5,
    "ansiedad": 3.2,
    "estres": 3.5,
    "apoyo": 1.0
  }},
  "descripcion": "...",
  "recomendaciones": [
    "...", "...", "..."
  ]
}}

Respuestas del usuario:
{respuestas_texto}
"""
    return prompt.strip()

# ------------------ RUTA PRINCIPAL ------------------
@router.post("/evaluar-estado-emocional")
async def evaluar_estado_emocional(data: RespuestaFormulario, db: Session = Depends(get_db)):
    try:
        prompt = construir_prompt(data.respuestas)

        response = openai.ChatCompletion.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "Eres un psicólogo clínico experto en salud mental."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=800
        )

        content = response["choices"][0]["message"]["content"]
        resultado = eval(content)  # �� se puede cambiar por json.loads si DeepSeek devuelve JSON puro

        estado = EstadoPsicologico(
            id=str(uuid.uuid4()),
            usuario_id=data.usuario_id,
            nivel=resultado.get("nivel", "amarillo"),
            descripcion=resultado.get("descripcion", ""),
            fecha=datetime.utcnow()
        )

        db.add(estado)
        db.commit()

        return {
            "mensaje": "Evaluación completada exitosamente.",
            "estado": {
                "nivel": estado.nivel,
                "descripcion": estado.descripcion
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/activar-evaluacion-inicial")
async def activar_evaluacion_inicial(usuario_id: str, db: Session = Depends(get_db)):
    estado_existente = db.query(EstadoPsicologico)\
        .filter_by(usuario_id=usuario_id)\
        .first()

    if estado_existente:
        return {
            "estado": "ya_registrado",
            "mensaje": "El perfil psicológico ya fue evaluado previamente.",
        }

    return {
        "estado": "pendiente",
        "mensaje": "Perfil psicológico aún no evaluado. El formulario puede ser mostrado.",
    }
    