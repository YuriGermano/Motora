from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import veiculos, abastecimentos, servicos, alertas

# Cria as tabelas no banco de dados ao iniciar
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Motora API",
    description="""
## 🏎️ Motora — API de Controle de Manutenção Veicular

Sistema para registrar e gerenciar veículos, abastecimentos, serviços e alertas de manutenção.

### Endpoints disponíveis:
- **Veículos** — CRUD completo + dashboard resumo
- **Abastecimentos** — Registro de cada abastecimento com atualização automática de km
- **Serviços/Manutenção** — Histórico de manutenções realizadas
- **Alertas** — Lembretes por km ou por data
    """,
    version="1.0.0",
    contact={"name": "Equipe Motora"}
)

# Permite requisições do Flutter (qualquer origem em desenvolvimento)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra os roteadores
app.include_router(veiculos.router)
app.include_router(abastecimentos.router)
app.include_router(servicos.router)
app.include_router(alertas.router)


@app.get("/", tags=["Root"])
def root():
    """Endpoint raiz — verifica se a API está no ar."""
    return {
        "status": "online",
        "app": "Motora API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health", tags=["Root"])
def health_check():
    """Health check — usado pelo Flutter para verificar disponibilidade."""
    return {"status": "ok"}
