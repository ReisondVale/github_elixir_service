# GithubElixirService

GithubElixirService é uma aplicação escrita em Elixir, projetada para buscar dados de repositórios no GitHub (issues e contribuidores) e agendar o envio desses dados para um endereço do webhook.site após 24 horas.

O projeto utiliza Oban para gerenciamento de jobs, PostgreSQL como banco de dados e possui uma cobertura de testes unitários.

## 📋 Funcionalidades
- Busca issues e contribuidores de repositórios do GitHub usando a API oficial.
- Agenda o envio dos dados para um webhook configurável.
- Gerencia jobs agendados utilizando Oban.
- Fornece endpoints para interação com o serviço.

## ⚙️ Configuração e Execução
### 🚨 IMPORTANTE 🚨:
No arquivo `config.exs` é preciso configurar a variavel `:webhook_url`. Ao visitar o site [Webhook.site](https://webhook.site/) ele irá lhe fornecer um link com o id relacionado ao seu acesso, antes de executar a aplicação é necessário que configure o link fornecido para poder ter acesso ao webhook que a aplicação irá gerar.
No mesmo arquivo o tempo de agendamento (`:webhook_snooze_time`) também pode ser configurado, por padrão o envio dos dados está setado para 24 horas após a consulta.

### Pré-requisitos
1. Elixir e Erlang instalados (versão recomendada no arquivo mix.exs).
2. PostgreSQL configurado e rodando localmente.
3. Token GitHub (opcional, dependendo do volume de requisições, e se algum dos repositórios pesquisados for privado).
4. Curl ou Postman para executar a aplicação.

### Passos para execução
1. Clone este repositório:

```
git clone https://github.com/seu_usuario/github_elixir_service.git
````
```
cd github_elixir_service
```

2. Instale as dependências:
```
mix deps.get
```
3. Configure o banco de dados:

- No arquivo `config/dev.exs` você encontra as informações para criar ou editar seu banco.
- Crie e migre o banco de dados:
````
mix ecto.setup
````
4. Inicie o servidor:
```
mix phx.server
```

## 🛠️ Uso
### Endpoints Disponíveis
`POST /fetch_data_issues`

Descrição: Realiza a busca de issues e contribuidores de um determinado repositorio no GitHub, e agenda o envio dos dados ao webhook configurado.

Payload esperado:
```
{
  "user": "nome_do_usuario",
  "repository": "nome_do_repositorio"
}
```
Exemplo de uso com curl:
```
curl -X POST http://localhost:4000/webhook/fetch_data_issues \
     -H "Content-Type: application/json" \
     -d '{"user": "elixir-lang", "repository": "elixir"}'
```
## 🧪 Testes
### Execute os testes com o comando:
```
mix test
```
## 📚 Estrutura do Projeto
- lib/: Contém os módulos principais da aplicação.
- lib/github_elixir_service/:
  - GithubClient: Responsável por buscar dados da API do GitHub.
  - ObanWorker.WebhookWorker: Gerencia os jobs agendados.
- lib/github_elixir_service_web/controllers/:
  - webhook_controller: Lida com a requisição recebida
- test/: Contém os testes unitários.
- config/: Arquivos de configuração do projeto.