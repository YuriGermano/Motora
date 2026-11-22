from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ─────────────────────────── VEÍCULO ───────────────────────────

class VeiculoBase(BaseModel):
    apelido: str = Field(..., examples=["Meu Civic"])
    marca: str = Field(..., examples=["Honda"])
    modelo: str = Field(..., examples=["Civic"])
    ano: int = Field(..., examples=[2020])
    placa: str = Field(..., examples=["ABC-1234"])
    cor: Optional[str] = None
    combustivel: Optional[str] = "Gasolina"
    km_atual: Optional[float] = 0.0

class VeiculoCreate(VeiculoBase):
    pass

class VeiculoUpdate(BaseModel):
    apelido: Optional[str] = None
    marca: Optional[str] = None
    modelo: Optional[str] = None
    ano: Optional[int] = None
    placa: Optional[str] = None
    cor: Optional[str] = None
    combustivel: Optional[str] = None
    km_atual: Optional[float] = None

class VeiculoResponse(VeiculoBase):
    id: int
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ─────────────────────────── ABASTECIMENTO ───────────────────────────

class AbastecimentoBase(BaseModel):
    km_no_momento: float = Field(..., examples=[45200.0])
    litros: float = Field(..., examples=[40.5])
    preco_por_litro: float = Field(..., examples=[5.89])
    total: float = Field(..., examples=[238.55])
    posto: Optional[str] = None
    combustivel: Optional[str] = None
    tanque_cheio: Optional[int] = 1
    observacao: Optional[str] = None

class AbastecimentoCreate(AbastecimentoBase):
    veiculo_id: int

class AbastecimentoUpdate(BaseModel):
    km_no_momento: Optional[float] = None
    litros: Optional[float] = None
    preco_por_litro: Optional[float] = None
    total: Optional[float] = None
    posto: Optional[str] = None
    combustivel: Optional[str] = None
    tanque_cheio: Optional[int] = None
    observacao: Optional[str] = None

class AbastecimentoResponse(AbastecimentoBase):
    id: int
    veiculo_id: int
    data: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ─────────────────────────── SERVIÇO ───────────────────────────

class ServicoBase(BaseModel):
    km_no_momento: float = Field(..., examples=[45200.0])
    tipo: str = Field(..., examples=["Troca de óleo"])
    descricao: Optional[str] = None
    custo: Optional[float] = 0.0
    oficina: Optional[str] = None
    proxima_revisao_km: Optional[float] = None
    proxima_revisao_data: Optional[str] = None
    observacao: Optional[str] = None

class ServicoCreate(ServicoBase):
    veiculo_id: int

class ServicoUpdate(BaseModel):
    km_no_momento: Optional[float] = None
    tipo: Optional[str] = None
    descricao: Optional[str] = None
    custo: Optional[float] = None
    oficina: Optional[str] = None
    proxima_revisao_km: Optional[float] = None
    proxima_revisao_data: Optional[str] = None
    observacao: Optional[str] = None

class ServicoResponse(ServicoBase):
    id: int
    veiculo_id: int
    data: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ─────────────────────────── ALERTA ───────────────────────────

class AlertaBase(BaseModel):
    titulo: str = Field(..., examples=["Troca de óleo em breve"])
    descricao: Optional[str] = None
    km_limite: Optional[float] = None
    data_limite: Optional[str] = None
    ativo: Optional[int] = 1

class AlertaCreate(AlertaBase):
    veiculo_id: int

class AlertaUpdate(BaseModel):
    titulo: Optional[str] = None
    descricao: Optional[str] = None
    km_limite: Optional[float] = None
    data_limite: Optional[str] = None
    ativo: Optional[int] = None

class AlertaResponse(AlertaBase):
    id: int
    veiculo_id: int

    model_config = {"from_attributes": True}


# ─────────────────────────── RESUMO / DASHBOARD ───────────────────────────

class DashboardVeiculo(BaseModel):
    veiculo: VeiculoResponse
    total_abastecimentos: int
    total_gasto_combustivel: float
    total_servicos: int
    total_gasto_servicos: float
    ultimo_abastecimento: Optional[AbastecimentoResponse] = None
    ultimo_servico: Optional[ServicoResponse] = None
    alertas_ativos: int
