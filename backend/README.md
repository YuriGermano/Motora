# Como rodar a API Motora

## Pré-requisitos
- Python 3.10+

## Instalação

```bash
cd backend
pip install -r requirements.txt
```

## Executar

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Documentação interativa (Swagger)

Abra no navegador: http://localhost:8000/docs

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | /veiculos | Lista todos os veículos |
| POST | /veiculos | Cadastra novo veículo |
| GET | /veiculos/{id} | Busca veículo por ID |
| PUT | /veiculos/{id} | Atualiza veículo |
| DELETE | /veiculos/{id} | Remove veículo |
| GET | /veiculos/{id}/dashboard | Resumo/dashboard do veículo |
| GET | /abastecimentos/veiculo/{id} | Lista abastecimentos do veículo |
| POST | /abastecimentos | Registra abastecimento |
| PUT | /abastecimentos/{id} | Atualiza abastecimento |
| DELETE | /abastecimentos/{id} | Remove abastecimento |
| GET | /servicos/veiculo/{id} | Histórico de serviços |
| POST | /servicos | Registra serviço |
| PUT | /servicos/{id} | Atualiza serviço |
| DELETE | /servicos/{id} | Remove serviço |
| GET | /alertas/veiculo/{id} | Lista alertas do veículo |
| POST | /alertas | Cria alerta |
| PUT | /alertas/{id} | Atualiza alerta |
| DELETE | /alertas/{id} | Remove alerta |
| GET | /health | Health check |
