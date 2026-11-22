from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class Veiculo(Base):
    """Tabela de veículos cadastrados."""
    __tablename__ = "veiculos"

    id = Column(Integer, primary_key=True, index=True)
    apelido = Column(String(50), nullable=False)          # Ex: "Meu Civic"
    marca = Column(String(50), nullable=False)
    modelo = Column(String(50), nullable=False)
    ano = Column(Integer, nullable=False)
    placa = Column(String(10), unique=True, nullable=False)
    cor = Column(String(30))
    combustivel = Column(String(20), default="Gasolina")  # Gasolina, Etanol, Flex, Diesel
    km_atual = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relacionamentos
    abastecimentos = relationship("Abastecimento", back_populates="veiculo", cascade="all, delete-orphan")
    servicos = relationship("Servico", back_populates="veiculo", cascade="all, delete-orphan")
    alertas = relationship("Alerta", back_populates="veiculo", cascade="all, delete-orphan")


class Abastecimento(Base):
    """Tabela de registros de abastecimento."""
    __tablename__ = "abastecimentos"

    id = Column(Integer, primary_key=True, index=True)
    veiculo_id = Column(Integer, ForeignKey("veiculos.id"), nullable=False)
    data = Column(DateTime(timezone=True), server_default=func.now())
    km_no_momento = Column(Float, nullable=False)
    litros = Column(Float, nullable=False)
    preco_por_litro = Column(Float, nullable=False)
    total = Column(Float, nullable=False)
    posto = Column(String(100))
    combustivel = Column(String(20))  # pode ser diferente do veiculo (flex)
    tanque_cheio = Column(Integer, default=1)  # 1 = sim, 0 = não
    observacao = Column(Text)

    veiculo = relationship("Veiculo", back_populates="abastecimentos")


class Servico(Base):
    """Tabela de serviços e manutenções realizadas."""
    __tablename__ = "servicos"

    id = Column(Integer, primary_key=True, index=True)
    veiculo_id = Column(Integer, ForeignKey("veiculos.id"), nullable=False)
    data = Column(DateTime(timezone=True), server_default=func.now())
    km_no_momento = Column(Float, nullable=False)
    tipo = Column(String(50), nullable=False)         # Ex: "Troca de óleo", "Revisão"
    descricao = Column(Text)
    custo = Column(Float, default=0.0)
    oficina = Column(String(100))
    proxima_revisao_km = Column(Float)                # km previsto para a próxima revisão
    proxima_revisao_data = Column(String(20))         # data prevista (string para simplicidade)
    observacao = Column(Text)

    veiculo = relationship("Veiculo", back_populates="servicos")


class Alerta(Base):
    """Tabela de alertas e lembretes de manutenção."""
    __tablename__ = "alertas"

    id = Column(Integer, primary_key=True, index=True)
    veiculo_id = Column(Integer, ForeignKey("veiculos.id"), nullable=False)
    titulo = Column(String(100), nullable=False)
    descricao = Column(Text)
    km_limite = Column(Float)         # alerta quando km_atual >= km_limite
    data_limite = Column(String(20))  # alerta na data
    ativo = Column(Integer, default=1)

    veiculo = relationship("Veiculo", back_populates="alertas")
