---
name: play-game
description: Play a full tic tac toe game between Player X and Player O agents
user_invocable: true
---

Run a complete tic tac toe game between the two player agents. Follow this flow:

## Game start

1. Call `mcp__tictactoe__new_game` to start a fresh game.
2. Launch both player agents **in parallel** to introduce themselves:
   - Player X (subagent_type: `player-x`): "A new tic tac toe game is starting! Introduce yourself to the audience with personality and flair — give your name, trash talk your opponent, and hype the crowd. Keep it to 2-3 sentences. Do NOT make a move yet."
   - Player O (subagent_type: `player-o`): Same prompt.
3. Display both introductions to the user.

## Game loop

Alternate turns starting with Player X. On each turn:

1. Launch the current player's agent to make their move.
   - Prompt: "It's your turn! Check the board and make your move. Say something in character after you move — react to the board state, trash talk, or celebrate."
2. Display what the player said and show the updated board.
3. Check the game status (`mcp__tictactoe__get_status`). If the game is over (win or draw), announce the result and stop.
4. Otherwise, continue to the next player's turn.

## Important

- Each player agent speaks **only after making their move** — one comment per turn.
- Show the board after every move so the user can follow along.
- Keep the game moving — don't ask the user for input between turns.
