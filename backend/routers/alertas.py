from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/alertas", tags=["Alertas"])


@router.get("/veiculo/{veiculo_id}", response_model=List[schemas.AlertaResponse],
            summary="Listar alertas de um veículo")
def listar_alertas(veiculo_id: int, db: Session = Depends(get_db)):
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    return db.query(models.Alerta).filter(models.Alerta.veiculo_id == veiculo_id).all()


@router.post("/", response_model=schemas.AlertaResponse,
             status_code=status.HTTP_201_CREATED, summary="Criar alerta de manutenção")
def criar_alerta(dados: schemas.AlertaCreate, db: Session = Depends(get_db)):
    """Cria um lembrete de manutenção por km ou por data."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == dados.veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    db_alerta = models.Alerta(**dados.model_dump())
    db.add(db_alerta)
    db.commit()
    db.refresh(db_alerta)
    return db_alerta


@router.put("/{alerta_id}", response_model=schemas.AlertaResponse, summary="Atualizar alerta")
def atualizar_alerta(alerta_id: int, dados: schemas.AlertaUpdate, db: Session = Depends(get_db)):
    alerta = db.query(models.Alerta).filter(models.Alerta.id == alerta_id).first()
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta não encontrado")
    for campo, valor in dados.model_dump(exclude_unset=True).items():
        setattr(alerta, campo, valor)
    db.commit()
    db.refresh(alerta)
    return alerta


@router.delete("/{alerta_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Excluir alerta")
def excluir_alerta(alerta_id: int, db: Session = Depends(get_db)):
    alerta = db.query(models.Alerta).filter(models.Alerta.id == alerta_id).first()
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta não encontrado")
    db.delete(alerta)
    db.commit()
