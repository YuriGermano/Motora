from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/veiculos", tags=["Veículos"])


@router.get("/", response_model=List[schemas.VeiculoResponse], summary="Listar todos os veículos")
def listar_veiculos(db: Session = Depends(get_db)):
    """Retorna lista de todos os veículos cadastrados."""
    return db.query(models.Veiculo).all()


@router.get("/{veiculo_id}", response_model=schemas.VeiculoResponse, summary="Buscar veículo por ID")
def buscar_veiculo(veiculo_id: int, db: Session = Depends(get_db)):
    """Retorna um veículo específico pelo ID."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    return veiculo


@router.post("/", response_model=schemas.VeiculoResponse, status_code=status.HTTP_201_CREATED,
             summary="Cadastrar novo veículo")
def criar_veiculo(veiculo: schemas.VeiculoCreate, db: Session = Depends(get_db)):
    """Cadastra um novo veículo. A placa deve ser única."""
    # Verifica placa duplicada
    existente = db.query(models.Veiculo).filter(models.Veiculo.placa == veiculo.placa).first()
    if existente:
        raise HTTPException(status_code=400, detail="Já existe um veículo com essa placa")

    db_veiculo = models.Veiculo(**veiculo.model_dump())
    db.add(db_veiculo)
    db.commit()
    db.refresh(db_veiculo)
    return db_veiculo


@router.put("/{veiculo_id}", response_model=schemas.VeiculoResponse, summary="Atualizar veículo")
def atualizar_veiculo(veiculo_id: int, dados: schemas.VeiculoUpdate, db: Session = Depends(get_db)):
    """Atualiza os dados de um veículo. Apenas os campos enviados são alterados."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")

    for campo, valor in dados.model_dump(exclude_unset=True).items():
        setattr(veiculo, campo, valor)

    db.commit()
    db.refresh(veiculo)
    return veiculo


@router.delete("/{veiculo_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Excluir veículo")
def excluir_veiculo(veiculo_id: int, db: Session = Depends(get_db)):
    """Remove um veículo e todos os seus registros associados (cascade)."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    db.delete(veiculo)
    db.commit()


@router.get("/{veiculo_id}/dashboard", response_model=schemas.DashboardVeiculo,
            summary="Dashboard resumo do veículo")
def dashboard_veiculo(veiculo_id: int, db: Session = Depends(get_db)):
    """Retorna resumo completo: gastos, último abastecimento, último serviço e alertas ativos."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")

    abastecimentos = db.query(models.Abastecimento).filter(
        models.Abastecimento.veiculo_id == veiculo_id).all()
    servicos = db.query(models.Servico).filter(
        models.Servico.veiculo_id == veiculo_id).all()
    alertas_ativos = db.query(models.Alerta).filter(
        models.Alerta.veiculo_id == veiculo_id,
        models.Alerta.ativo == 1).count()

    ultimo_abastecimento = db.query(models.Abastecimento).filter(
        models.Abastecimento.veiculo_id == veiculo_id
    ).order_by(models.Abastecimento.data.desc()).first()

    ultimo_servico = db.query(models.Servico).filter(
        models.Servico.veiculo_id == veiculo_id
    ).order_by(models.Servico.data.desc()).first()

    return schemas.DashboardVeiculo(
        veiculo=veiculo,
        total_abastecimentos=len(abastecimentos),
        total_gasto_combustivel=sum(a.total for a in abastecimentos),
        total_servicos=len(servicos),
        total_gasto_servicos=sum(s.custo for s in servicos),
        ultimo_abastecimento=ultimo_abastecimento,
        ultimo_servico=ultimo_servico,
        alertas_ativos=alertas_ativos,
    )
