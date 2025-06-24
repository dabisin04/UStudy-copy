from fastapi import FastAPI, Request
from routers import usuario as usuario_router
from models import usuario as usuario_model
from config import engine, Base

Base.metadata.create_all(bind=engine)

# Crear instancia de FastAPI
app = FastAPI()

# Registrar rutas
app.include_router(usuario_router.router, prefix="/usuarios")
