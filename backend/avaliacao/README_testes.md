# Roteiro de testes para o capítulo 6

Ordem sugerida de execução. O tempo total fica em torno de 2 h, das quais
apenas ~25 min são de espera automática.

Todos os comandos partem de `backend/`, com o venv da raiz:

```
cd backend
../.venv/Scripts/python.exe avaliacao/medir_ia.py --help
```

---

## T1 — Bateria principal (Quadros 4, 5 e 7)

Não grava nada no banco: os perfis são objetos em memória.

```
../.venv/Scripts/python.exe avaliacao/medir_ia.py --repeticoes 10
```

40 gerações (4 perfis × 10). Em Haiku 4.5 leva ~8 min e custa centavos.
Gera dois CSVs em `avaliacao/resultados/` e imprime o resumo já no formato
do Quadro 5.

O que sai dali:

| Número do documento | Onde encontrar |
|---|---|
| Gerações executadas, aprovadas e reprovadas | resumo no terminal |
| Motivo predominante de reprovação | resumo (`motivos`) |
| Tempo médio / mín / máx | resumo |
| Proporção que cairia no motor de regras | resumo |
| Repetições e descanso por objetivo | `prescricoes_*.csv`, coluna `dentro_da_faixa_literatura` |
| Aderência às regras de cautela | resumo, bloco "Aderência às regras de cautela" |
| Cobertura do foco muscular | resumo, linhas de grupos fora/ignorados |

> **Atenção ao bloco de cautela.** Essas quatro regras existem só no texto do
> prompt — `_validar` não as verifica. O teste de fumaça já registrou
> violações (ressalva como primeiro exercício do dia e mais de uma no mesmo
> dia). Decida antes de rodar a bateria final: ou você as promove para dentro
> de `_validar` e mede de novo (vira mais uma iteração documentada, como a do
> `plano_com_dias`), ou mantém como está e usa o número como evidência de que
> regra crítica precisa estar em código. As duas saídas servem ao argumento;
> a segunda é mais honesta e mais rápida.

## T2 — Comparação entre modelos (opcional, mas rende um quadro)

```
../.venv/Scripts/python.exe avaliacao/medir_ia.py --repeticoes 5 --modelo claude-opus-5
```

Compare taxa de conformidade e latência com o resultado do T1. Justifica com
dado a parametrização por variável de ambiente descrita na seção 5.6.

> Ao usar Opus ou Sonnet, defina também `IA_EFFORT` (low/medium/high) no
> `.env`; o Haiku 4.5 não aceita esse parâmetro.

## T3 — Falhas induzidas (Quadro 6)

Aqui o objetivo é o caminho de contingência, então **roda pela aplicação de
verdade**, com o servidor no ar e gravando no banco. Uma execução por cenário
basta. Antes de cada uma, anote o `id_usuario` de teste.

1. **Sem credencial** — comente `ANTHROPIC_API_KEY` no `.env`, reinicie o
   servidor e chame `POST /api/treinos/gerar/{id_usuario}`. Esperado: duas
   tentativas no log e ficha com `origem = 'regra'`.
2. **Sem rede** — desligue o Wi-Fi da máquina do servidor e repita a chamada.
   Esperado: o mesmo, com exceção de rede no log.
3. **Reprovação na validação** — com a chave ativa, altere temporariamente
   `MIN_EXERCICIOS_DIA = 7` e `MAX_EXERCICIOS_DIA = 7` em
   `services/ia_treino_service.py` **sem tocar no texto das instruções**. O
   modelo continuará devolvendo 4–6 exercícios e a validação vai reprovar.
   Esperado: `qtd_exercicios_fora_da_faixa` no log e queda para o motor de
   regras. Desfaça a alteração depois.
4. **Falha na persistência** — opcional; se quiser cobrir a linha, force uma
   exceção dentro do laço de `_persistir` e confirme que os dias já gravados
   ficam com `st_ativo = false`.

Capture o log de cada cenário (Figura 10) e a consulta de `tb_treino`
(Figura 11).

## T4 — Evidências no banco

```sql
-- Figura 5: hash bcrypt no lugar da senha
SELECT id_usuario, nm_usuario, em_usuario, pwd_usuario,
       qtd_dias, objetivo, foco, peso, altura
FROM tb_usuario WHERE id_usuario = :id;

-- Figura 11: origem da ficha e justificativa nula no motor de regras
SELECT id_treino, id_usuario, dia_treino, st_ativo, origem,
       dt_criacao, LEFT(justificativa, 60) AS justificativa
FROM tb_treino WHERE id_usuario IN (:id_ia, :id_regra)
ORDER BY id_usuario, dia_treino;

-- Quadro 4: nenhum exercício bloqueado pode aparecer na ficha (deve vir vazio)
SELECT DISTINCT e.nm_exercicio, l.nm_lesao, el.nivel
FROM tb_treino t
JOIN tb_treino_exercicio te ON te.id_treino = t.id_treino
JOIN tb_exercicios e        ON e.id_exercicio = te.id_exercicio
JOIN tb_exercicio_lesao el  ON el.id_exercicio = e.id_exercicio
JOIN tb_usuario_lesao ul    ON ul.id_lesao = el.id_lesao AND ul.id_usuario = t.id_usuario
JOIN tb_lesoes l            ON l.id_lesao = el.id_lesao
WHERE t.id_usuario = :id AND t.st_ativo = true AND el.nivel = 'bloqueio';

-- Quadro 4 (linhas de cautela efetivamente prescritas)
-- mesma consulta com el.nivel = 'cautela'

-- Figura 14: registros que alimentam o gráfico de frequência
SELECT * FROM tb_frequencia WHERE id_usuario = :id ORDER BY dt_registro;
```

## T5 — Capturas de tela

Cadastre um usuário pelo app para cada perfil que for aparecer em figura.
Lista do que capturar, na ordem do documento:

| Figura | Tela |
|---|---|
| 4 | Cadastro: credenciais, objetivo/foco/dias, seleção de lesões |
| 5 | Banco: `tb_usuario` (consulta acima) |
| 6 | Terminal: catálogo de P1 vs P2 (o script imprime o tamanho; para o conteúdo, `print(catalogo)`) |
| 7 | App: exercício sob ressalva na tela de treino |
| 8 | Terminal: JSON da resposta (recortar 1–2 dias) |
| 9 | App: bloco de justificativa |
| 10 | Terminal: log da contingência (T3) |
| 11 | Banco: `tb_treino` com as duas origens |
| 12 | App: listagem dos dias |
| 13 | App: execução, cronômetro, exercícios concluídos |
| 14 | App: gráfico de frequência + consulta |
| 15 | Navegador/terminal: JSON de `/api/usuarios/{id}/restricoes` para P3 |
| 16 | App: aviso nos dois patamares e recolhido |

Para a Figura 16(b), use o P3: as lesões dele zeram quadríceps,
isquiotibiais, glúteos e panturrilha, que é exatamente o caso grave.

---

## Observação já levantada pelo teste de fumaça

`tokens_cache_lido` e `tokens_cache_criado` vieram **zerados** com o Haiku 4.5:
o bloco de sistema (~2,2 mil tokens) fica no limite do mínimo exigido para
cache nesse modelo. Confira essas colunas no CSV do T1 antes de afirmar, na
seção 5.6 e na 6.3, que o cache reduz o custo das chamadas subsequentes. Se
continuarem zeradas, há duas saídas honestas: descrever a marcação de cache
como decisão de projeto cujo efeito só se manifesta em modelos/prompt maiores,
ou medir de novo no T2 com Opus e reportar o número de lá.
