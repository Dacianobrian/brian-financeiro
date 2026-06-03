# Brian Financeiro

Sistema financeiro pessoal gratuito para GitHub Pages + Supabase.

## Publicacao

Este repositorio usa GitHub Actions para publicar automaticamente no GitHub Pages sempre que houver push na branch `main`.

URL esperada depois do deploy:

`https://dacianobrian.github.io/brian-financeiro/`

## Supabase

1. Crie um projeto no painel do Supabase.
2. Rode o SQL de `supabase/schema.sql` no SQL Editor.
3. Copie `Project URL` e `anon public key`.
4. Atualize `config.js`.

Use apenas a chave `anon public`. Nunca publique `service_role`.

## Recursos

- Login/cadastro por Supabase Auth.
- Dashboard mensal.
- Lancamentos.
- Importador basico da planilha anual.
- Simulador de compra com alerta vermelho.
- Contas fixas recorrentes.
- Orcamento por categoria.
- RLS por usuario no banco.
