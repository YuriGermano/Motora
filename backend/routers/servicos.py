from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/servicos", tags=["Serviços / Manutenção"])


@router.get("/veiculo/{veiculo_id}", response_model=List[schemas.ServicoResponse],
            summary="Histórico de serviços de um veículo")
def listar_servicos(veiculo_id: int, db: Session = Depends(get_db)):
    """Retorna todo o histórico de manutenção de um veículo."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    return db.query(models.Servico).filter(
        models.Servico.veiculo_id == veiculo_id
    ).order_by(models.Servico.data.desc()).all()


@router.get("/{servico_id}", response_model=schemas.ServicoResponse,
            summary="Buscar serviço por ID")
def buscar_servico(servico_id: int, db: Session = Depends(get_db)):
    servico = db.query(models.Servico).filter(models.Servico.id == servico_id).first()
    if not servico:
        raise HTTPException(status_code=404, detail="Serviço não encontrado")
    return servico


@router.post("/", response_model=schemas.ServicoResponse,
             status_code=status.HTTP_201_CREATED, summary="Registrar serviço/manutenção")
def registrar_servico(dados: schemas.ServicoCreate, db: Session = Depends(get_db)):
    """
    Registra um serviço ou manutenção realizada no veículo.
    Atualiza a km do veículo automaticamente se necessário.
    """
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == dados.veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")

    db_servico = models.Servico(**dados.model_dump())
    db.add(db_servico)

    # Atualiza km do veículo se for maior que a atual
    if dados.km_no_momento > veiculo.km_atual:
        veiculo.km_atual = dados.km_no_momento

    db.commit()
    db.refresh(db_servico)
    return db_servico


@router.put("/{servico_id}", response_model=schemas.ServicoResponse,
            summary="Atualizar serviço")
def atualizar_servico(servico_id: int, dados: schemas.ServicoUpdate, db: Session = Depends(get_db)):
    servico = db.query(models.Servico).filter(models.Servico.id == servico_id).first()
    if not servico:
        raise HTTPException(status_code=404, detail="Serviço não encontrado")

    for campo, valor in dados.model_dump(exclude_unset=True).items():
        setattr(servico, campo, valor)

    db.commit()
    db.refresh(servico)
    return servico


@router.delete("/{servico_id}", status_code=status.HTTP_204_NO_CONTENT,
               summary="Excluir serviço")
def excluir_servico(servico_id: int, db: Session = Depends(get_db)):
    servico = db.query(models.Servico).filter(models.Servico.id == servico_id).first()
    if not servico:
        raise HTTPException(status_code=404, detail="Serviço não encontrado")
    db.delete(servico)
    db.commit()
