from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/abastecimentos", tags=["Abastecimentos"])


@router.get("/veiculo/{veiculo_id}", response_model=List[schemas.AbastecimentoResponse],
            summary="Listar abastecimentos de um veículo")
def listar_abastecimentos(veiculo_id: int, db: Session = Depends(get_db)):
    """Retorna todos os abastecimentos de um veículo, do mais recente ao mais antigo."""
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    return db.query(models.Abastecimento).filter(
        models.Abastecimento.veiculo_id == veiculo_id
    ).order_by(models.Abastecimento.data.desc()).all()


@router.get("/{abastecimento_id}", response_model=schemas.AbastecimentoResponse,
            summary="Buscar abastecimento por ID")
def buscar_abastecimento(abastecimento_id: int, db: Session = Depends(get_db)):
    abastecimento = db.query(models.Abastecimento).filter(
        models.Abastecimento.id == abastecimento_id).first()
    if not abastecimento:
        raise HTTPException(status_code=404, detail="Abastecimento não encontrado")
    return abastecimento


@router.post("", response_model=schemas.AbastecimentoResponse,
             status_code=status.HTTP_201_CREATED, summary="Registrar abastecimento")
@router.post("/", response_model=schemas.AbastecimentoResponse,
             status_code=status.HTTP_201_CREATED, include_in_schema=False)
def registrar_abastecimento(dados: schemas.AbastecimentoCreate, db: Session = Depends(get_db)):
    """
    Registra um novo abastecimento e atualiza automaticamente a quilometragem atual do veículo.
    """
    veiculo = db.query(models.Veiculo).filter(models.Veiculo.id == dados.veiculo_id).first()
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")

    # Validação de km
    if dados.km_no_momento < veiculo.km_atual:
        raise HTTPException(
            status_code=400,
            detail=f"A km informada ({dados.km_no_momento}) é menor que a km atual do veículo ({veiculo.km_atual})"
        )

    # Preenche combustivel padrão do veículo se não informado
    if not dados.combustivel:
        dados.combustivel = veiculo.combustivel

    db_abastecimento = models.Abastecimento(**dados.model_dump())
    db.add(db_abastecimento)

    # Atualiza km do veículo
    veiculo.km_atual = dados.km_no_momento
    db.commit()
    db.refresh(db_abastecimento)
    return db_abastecimento


@router.put("/{abastecimento_id}", response_model=schemas.AbastecimentoResponse,
            summary="Atualizar abastecimento")
def atualizar_abastecimento(abastecimento_id: int, dados: schemas.AbastecimentoUpdate,
                             db: Session = Depends(get_db)):
    abastecimento = db.query(models.Abastecimento).filter(
        models.Abastecimento.id == abastecimento_id).first()
    if not abastecimento:
        raise HTTPException(status_code=404, detail="Abastecimento não encontrado")

    for campo, valor in dados.model_dump(exclude_unset=True).items():
        setattr(abastecimento, campo, valor)

    db.commit()
    db.refresh(abastecimento)
    return abastecimento


@router.delete("/{abastecimento_id}", status_code=status.HTTP_204_NO_CONTENT,
               summary="Excluir abastecimento")
def excluir_abastecimento(abastecimento_id: int, db: Session = Depends(get_db)):
    abastecimento = db.query(models.Abastecimento).filter(
        models.Abastecimento.id == abastecimento_id).first()
    if not abastecimento:
        raise HTTPException(status_code=404, detail="Abastecimento não encontrado")
    db.delete(abastecimento)
    db.commit()
