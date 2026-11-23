# Motora - Sistema de Controle de Manutencao Veicular

O Motora e uma solucao completa para gerenciamento e controle de veiculos, abastecimentos, servicos de manutencao e alertas preventivos. O projeto e composto por uma API REST em Python e um aplicativo multiplataforma desenvolvido em Flutter.

---

## Principais Ferramentas e Tecnologias

### Backend
- Python 3.12: Linguagem base utilizada para a construcao da API.
- FastAPI: Framework web moderno e assincrono para criacao de APIs REST de alta performance com validacao automatica e documentacao interativa.
- Uvicorn: Servidor ASGI rapido utilizado para executar a aplicacao FastAPI.
- SQLAlchemy: Biblioteca de ORM (Object Relational Mapping) para mapeamento das tabelas e persistencia de dados.
- SQLite: Banco de dados relacional embarcado, dispensando a instalacao de servidores adicionais de banco.
- Pydantic: Biblioteca para definicao de esquemas de dados, tipagem estrita e validacao de entradas e saidas.

### Frontend / Mobile
- Flutter / Dart: Framework de desenvolvimento de interface de usuario para criacao de aplicativos nativos multiplataforma a partir de uma unica base de codigo.
- http: Pacote responsavel pela comunicacao e consumo dos endpoints HTTP da API REST.
- intl: Pacote para internacionalizacao e formatacao de valores monetarios, datas e numeros.
- share_plus: Plugin de integracao nativa para exportacao e compartilhamento de relatorios do veiculo por aplicativos como WhatsApp, Gmail e outros.
- mask_text_input_formatter: Formatador dinamico de entrada de texto utilizado no formulario para suportar placas tanto no padrao Mercosul (ex: ABC1D23) quanto no padrao tradicional (ex: ABC-1234).

---

## Funcionalidades do Sistema

- Gestao de Veiculos: Cadastro, atualizacao, listagem e exclusao de veiculos com validacao e mascara de placas.
- Controle de Abastecimentos: Registro com odometro, tipo de combustivel, litros, valor por litro e indicador de tanque cheio.
- Calculo de Consumo Medio (km/l): Calculo automatico do consumo entre abastecimentos consecutivos com tanque cheio, exibido na tela de abastecimentos e no dashboard.
- Historico de Servicos e Manutencao: Registro detalhado de revisoes e reparos, com pesquisa textual, filtros por tipo de servico, selecao por mes e ordenacao configuravel.
- Alertas e Notificacoes: Monitoramento de revisoes e prazos por quilometragem ou por data.
- Dashboard e Relatorios: Painel com estatisticas financeiras consolidadas e botao de compartilhamento de relatorio em texto.

---

## Pre-requisitos

Para executar o projeto localmente, e necessario ter instalado:
- Git
- Python 3.10 ou superior
- Flutter SDK 3.0 ou superior (com Android SDK configurado para execucao mobile)

---

## Como Executar o Sistema

### 1. Executando o Backend (API)

Abra um terminal na raiz do projeto e siga os passos abaixo:

#### Metodo Automatico (Windows):
Navegue ate a pasta do backend e execute o script de inicializacao:
```powershell
cd backend
.\iniciar_api.bat
```
O script verifica o ambiente Python, instala as dependencias do `requirements.txt`, popula a base de dados inicial com `seed_data.py` e inicia o servidor Uvicorn.

#### Metodo Manual:
```bash
# 1. Acessar a pasta do backend
cd backend

# 2. Criar e ativar o ambiente virtual (opcional, porem recomendado)
python -m venv venv

# No Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# No Linux/macOS:
source venv/bin/activate

# 3. Instalar as dependencias
pip install -r requirements.txt

# 4. (Opcional) Popular o banco de dados com dados de exemplo
python seed_data.py

# 5. Iniciar o servidor FastAPI
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Apos iniciar, o backend estara disponivel em:
- API Base: `http://localhost:8000`
- Documentacao Interativa (Swagger UI): `http://localhost:8000/docs`
- Documentacao Alternativa (ReDoc): `http://localhost:8000/redoc`

---

### 2. Configurando o IP da API no Aplicativo

Antes de iniciar o aplicativo Flutter, verifique o endereco configurado em `motora_app/lib/services/api_service.dart`:

```dart
// Em motora_app/lib/services/api_service.dart
static const String baseUrl = 'http://10.0.30.197:8000';
```

- Para teste em Smartphone fisico: O smartphone e o computador devem estar na mesma rede Wi-Fi. Mantenha o endereco com o IP local do seu computador na rede (exemplo: `http://10.0.30.197:8000`).
- Para Emulador Android oficial: O endereco deve ser alterado para `http://10.0.2.2:8000`.
- Para Windows Desktop ou Navegador Web: O endereco pode ser `http://localhost:8000` ou `http://127.0.0.1:8000`.

---

### 3. Executando o Aplicativo Mobile (Flutter)

Em outro terminal, acesse a pasta do aplicativo Flutter:

```bash
# 1. Entrar na pasta do app
cd motora_app

# 2. Baixar as dependencias do Flutter
flutter pub get

# 3. Listar dispositivos conectados disponiveis
flutter devices

# 4. Executar o app no dispositivo desejado
flutter run
```

---

## Estrutura do Projeto

```text
Motora/
├── backend/
│   ├── routers/
│   │   ├── abastecimentos.py      # Endpoints de abastecimentos
│   │   ├── alertas.py             # Endpoints de alertas de manutencao
│   │   ├── servicos.py            # Endpoints de servicos e reparos
│   │   └── veiculos.py            # Endpoints de CRUD e dashboard de veiculos
│   ├── database.py                # Conexao com o SQLite e sessao do SQLAlchemy
│   ├── iniciar_api.bat            # Script de inicializacao rapida para Windows
│   ├── iniciar_api.ps1            # Script de inicializacao em PowerShell
│   ├── main.py                    # Ponto de entrada FastAPI e configuracao de CORS
│   ├── models.py                  # Modelos das tabelas do SQLAlchemy
│   ├── requirements.txt           # Dependencias Python
│   ├── schemas.py                 # Esquemas Pydantic para validacao de dados
│   └── seed_data.py               # Script para insercao de dados de exemplo
│
├── motora_app/
│   ├── lib/
│   │   ├── models/
│   │   │   └── models.dart        # Modelos de dados e logica de calculo de consumo
│   │   ├── screens/
│   │   │   ├── abastecimento_screen.dart   # Listagem e cadastro de abastecimentos
│   │   │   ├── alertas_screen.dart         # Monitoramento de alertas
│   │   │   ├── cadastrar_veiculo_screen.dart # Formulario de veiculos com mascara
│   │   │   ├── home_screen.dart            # Listagem principal de veiculos
│   │   │   ├── servicos_screen.dart        # Listagem de servicos com filtros e busca
│   │   │   └── veiculo_detail_screen.dart  # Detalhes, estatisticas e exportacao
│   │   ├── services/
│   │   │   └── api_service.dart   # Camada central de integracao HTTP com o backend
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Cores e tema visual padronizado do aplicativo
│   │   └── main.dart              # Ponto de entrada do aplicativo Flutter
│   └── pubspec.yaml               # Dependencias e configuracoes do projeto Flutter
│
├── .gitignore                     # Regras globais de exclusao do Git
└── README.md                      # Documentacao principal do repositorio
```
