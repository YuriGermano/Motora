"""
Script para popular o banco de dados com dados de teste para a apresentação.
Rode: python seed_data.py
"""
import sys
from datetime import datetime
from database import SessionLocal, engine, Base
import models

# Garante que as tabelas existem
Base.metadata.create_all(bind=engine)

def popular_banco():
    db = SessionLocal()
    try:
        # Verifica se já há dados
        if db.query(models.Veiculo).count() > 0:
            print("O banco de dados já possui registros.")
            return

        print("Populando banco de dados para a demonstração...")

        # 1. Veículo 1 - Honda Civic
        civic = models.Veiculo(
            apelido="Civic G10",
            marca="Honda",
            modelo="Civic Touring 1.5 Turbo",
            ano=2021,
            placa="BRA2E19",
            cor="Preto Cristal",
            combustivel="Gasolina",
            km_atual=45850.0,
        )
        db.add(civic)

        # 2. Veículo 2 - Fiat Strada
        strada = models.Veiculo(
            apelido="Strada de Trabalho",
            marca="Fiat",
            modelo="Strada Freedom 1.3",
            ano=2022,
            placa="MOT0R24",
            cor="Branco Banchisa",
            combustivel="Flex",
            km_atual=32100.0,
        )
        db.add(strada)
        db.commit()
        db.refresh(civic)
        db.refresh(strada)

        # Abastecimentos do Civic
        abast1 = models.Abastecimento(
            veiculo_id=civic.id,
            km_no_momento=45200.0,
            litros=42.5,
            preco_por_litro=5.89,
            total=250.32,
            posto="Posto Ipiranga Centro",
            combustivel="Gasolina",
            tanque_cheio=1,
            observacao="Gasolina aditivada DT Clean",
        )
        abast2 = models.Abastecimento(
            veiculo_id=civic.id,
            km_no_momento=45850.0,
            litros=44.1,
            preco_por_litro=5.79,
            total=255.33,
            posto="Posto Shell Radial",
            combustivel="Gasolina",
            tanque_cheio=1,
            observacao="V-Power",
        )
        db.add_all([abast1, abast2])

        # Serviços do Civic
        serv1 = models.Servico(
            veiculo_id=civic.id,
            km_no_momento=40000.0,
            tipo="Troca de óleo",
            descricao="Troca de óleo sintético 0W-20 e filtro de óleo",
            custo=380.0,
            oficina="Concessionária Honda Daitan",
            proxima_revisao_km=50000.0,
            proxima_revisao_data="15/12/2026",
            observacao="Tudo em conformidade com o manual",
        )
        serv2 = models.Servico(
            veiculo_id=civic.id,
            km_no_momento=44500.0,
            tipo="Freios",
            descricao="Substituição das pastilhas de freio dianteiras",
            custo=420.0,
            oficina="Brembo Service",
            proxima_revisao_km=65000.0,
            observacao="Discos foram apenas retificados",
        )
        db.add_all([serv1, serv2])

        # Alertas do Civic
        alerta1 = models.Alerta(
            veiculo_id=civic.id,
            titulo="Revisão dos 50.000 km",
            descricao="Troca de velas de ignição e filtro de combustível",
            km_limite=50000.0,
            data_limite="15/12/2026",
            ativo=1,
        )
        alerta2 = models.Alerta(
            veiculo_id=civic.id,
            titulo="Rodízio e Balanceamento",
            descricao="Fazer rodízio de pneus aos 48.000 km",
            km_limite=48000.0,
            ativo=1,
        )
        db.add_all([alerta1, alerta2])

        db.commit()
        print("Banco de dados populado com sucesso!")
        print(f"Veículo 1: {civic.apelido} (ID: {civic.id})")
        print(f"Veículo 2: {strada.apelido} (ID: {strada.id})")

    except Exception as e:
        print(f"Erro ao popular: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    popular_banco()
