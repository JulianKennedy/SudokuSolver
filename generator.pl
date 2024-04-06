%%% ----------------------------------------------- %%%
%%% --------------------- GUI --------------------- %%%
%%% ----------------------------------------------- %%%

start :-
    writeln('Do you want to "create" or "solve" a Sudoku puzzle? (create/solve)'),
    read(UserChoice),
    process_choice(UserChoice).

process_choice(solve) :-
    writeln('Please input the entire Sudoku puzzle as a nested list (list of lists), then press Enter:'),
    read(Puzzle),
    (   is_valid_puzzle(Puzzle)
    ->  (   writeln('Solved puzzle below:'),
            solve_sudoku(Puzzle)
        ->  writeln('YAY, the puzzle can be solved!')
        ;   writeln('Could not solve the puzzle. Impossible puz')
        )
    ;   writeln('Invalid puzzle format.'),
        writeln('Please ensure it\'s a nested list with 9 lists, each containing 9 elements.'),
        process_choice(solve)
    ).

process_choice(create) :-
    choose_difficulty(Difficulty, Probability),
    repeat,
    %writeln('Generating Sudoku matrix...\n'),
    create_sudoku_matrix(Sudoku),
    %display_sudoku(Sudoku),
    check_validity(Sudoku),
    %writeln('All cells are valid!\n'),
    %writeln('Solving Sudoku matrix...\n'),
    potential_sudoku_solution(Sudoku, SudokuSolution),
    %display_sudoku(SudokuSolution),
    %writeln('\nProcessing solution...\n'),
    process_sudoku_matrix(SudokuSolution, Probability, ProcessedSudoku), % removal rate, adjust as needed
    check_validity(ProcessedSudoku),
    writeln('Starting Sudoku board: \n'),
    display_sudoku(ProcessedSudoku),
    !. % Cut to stop backtracking

process_choice(_) :-
    writeln('Invalid option. Please type "create" or "solve".'),
    start.

is_valid_puzzle(Puzzle) :-
    length(Puzzle, 9),
    maplist(length_(9), Puzzle).

length_(Length, List) :- length(List, Length).

choose_difficulty(Difficulty, Probability) :-
    writeln('Choose difficulty level: '),
    writeln('1. Easy'),
    writeln('2. Medium'),
    writeln('3. Hard'),
    read(DifficultyChoice),
    validate_difficulty(DifficultyChoice, Difficulty, Probability).

validate_difficulty(1, easy, 55).
validate_difficulty(2, medium, 65).
validate_difficulty(3, hard, 75).
validate_difficulty(_, easy, 65) :-
    writeln('Invalid choice. Defaulting to easy difficulty.').


%%% ----------------------------------------------- %%%
%%% ----------- Generating Sudoku Table ----------- %%%
%%% ----------------------------------------------- %%%

% Create a Sudoku matrix with 10% chance of a random value
% Define the predicate to create a 9x9 Sudoku matrix filled with 0s and some random values
create_sudoku_matrix(Matrix) :-
    length(Matrix, 9),
    maplist(create_row_random, Matrix).

% Define the predicate to create a single row filled with 0s and some random values
create_row_random(Row) :-
    length(Row, 9),
    maplist(randomize_cell, Row).

% Define the predicate to randomly assign a value between 1 and 9 to a cell with a probability of 10/81
randomize_cell(Cell) :-
    maybe_assign_value(Cell).

% Predicate to randomly assign a value between 1 and 9 with probability 10/81
maybe_assign_value(Value) :-
    random(1, 82, Random),
    (Random =< 10 -> random(1, 10, Value) ; Value = 0).

% Check that the Sudoku matrix is valid otherwise generate a new one
% Predicate to check the validity of all cells in the Sudoku matrix
check_validity(Sudoku) :-
    check_validity_cell(Sudoku, 1, 1).

% Predicate to check the validity of a single cell in the Sudoku matrix
check_validity_cell(Sudoku, 10, _) :- !.
check_validity_cell(Sudoku, RowIndex, 10) :-
    !, NextRow is RowIndex + 1,
    check_validity_cell(Sudoku, NextRow, 1).
check_validity_cell(Sudoku, RowIndex, ColIndex) :-
    nth1(RowIndex, Sudoku, Row),
    nth1(ColIndex, Row, Cell),
    (   Cell is 0
    ->  NextCol is ColIndex + 1,
        check_validity_cell(Sudoku, RowIndex, NextCol)
    ;   check_placement(Cell, Sudoku, RowIndex, ColIndex),
        NextCol is ColIndex + 1,
        check_validity_cell(Sudoku, RowIndex, NextCol)
    ).

% Placeholder predicate to check if a number can be placed in a specific row, column, and block
check_placement(Number, Rows, RowIndex, ColIndex) :-
    nth1(RowIndex, Rows, Row),
    no_duplicates(Row),
    extract_column(Rows, ColIndex, Column),
    no_duplicates(Column),
    BlockX is ((ColIndex - 1) // 3) + 1,
    BlockY is ((RowIndex - 1) // 3) + 1,
    extract_block(Rows, BlockX, BlockY, Block),
    no_duplicates(Block),
    dif(Number, Row),
    dif(Number, Column),
    dif(Number, Block).

% Check if a list does not contain any duplicates except 0
no_duplicates([]).
no_duplicates([Head|Tail]) :-
    member(Head, Tail), Head \= 0, !, fail.
no_duplicates([_|Tail]) :-
    no_duplicates(Tail).

% Extract a column from the Sudoku grid
extract_column([], _, []).
extract_column([Row|Matrix], ColIndex, [Item|Column]) :-
    nth1(ColIndex, Row, Item),
    extract_column(Matrix, ColIndex, Column).

% Extract a 3x3 block from the Sudoku grid
extract_block(Rows, BlockX, BlockY, Block) :-
    BlockStartRow is 1 + 3 * (BlockY - 1),
    BlockEndRow is 3 + 3 * (BlockY - 1),
    findall(Num, (between(BlockStartRow, BlockEndRow, RowIndex),
                  nth1(RowIndex, Rows, Row),
                  BlockStartCol is 1 + 3 * (BlockX - 1),
                  BlockEndCol is 3 + 3 * (BlockX - 1),
                  between(BlockStartCol, BlockEndCol, ColIndex),
                  nth1(ColIndex, Row, Num)), Block).

% Find a potential solution for the randomly generated Sudoku matrix
potential_sudoku_solution(Rows, SudokuSolution) :- solve_potential_cell(Rows, 1, 1, SudokuSolution).

solve_potential_cell(Rows, 10, _, Rows).
solve_potential_cell(Rows, RowIndex, 10, SudokuSolution) :-
    NextRow is RowIndex + 1,
    solve_potential_cell(Rows, NextRow, 1, SudokuSolution).
solve_potential_cell(Rows, RowIndex, ColIndex, SudokuSolution) :-
    nth1(RowIndex, Rows, Row),
    nth1(ColIndex, Row, Cell),
    (   Cell \= 0
    ->  NextCol is ColIndex + 1,
        solve_potential_cell(Rows, RowIndex, NextCol, SudokuSolution)
    ;   between(1, 9, Number),
        valid_placement(Number, Rows, RowIndex, ColIndex),
        replace(Row, ColIndex, Number, NewRow),
        replace(Rows, RowIndex, NewRow, NewRows),
        NextCol is ColIndex + 1,
        solve_potential_cell(NewRows, RowIndex, NextCol, SudokuSolution)
    ).


replace([_|T], 1, X, [X|T]).
replace([H|T], I, X, [H|R]) :-
    I > 1, 
    NI is I - 1, 
    replace(T, NI, X, R).

% Based on difficulty, remove the elements from the Sudoku matrix with a certain percentage chance
% Define the predicate to randomly remove elements from the Sudoku matrix based on a percentage
process_sudoku_matrix([], _, []).
process_sudoku_matrix([Row|Rows], Percentage, [ProcessedRow|ProcessedRows]) :-
    process_row(Row, Percentage, ProcessedRow),
    process_sudoku_matrix(Rows, Percentage, ProcessedRows).

% Define the predicate to randomly remove elements from a row based on a percentage
process_row([], _, []).
process_row([Cell|Cells], Percentage, [ProcessedCell|ProcessedCells]) :-
    maybe_remove(Cell, Percentage, ProcessedCell),
    process_row(Cells, Percentage, ProcessedCells).

% Predicate to randomly remove a value based on a percentage
maybe_remove(Cell, Percentage, NewCell) :-
    random(1, 101, Random),
    (Random =< Percentage -> NewCell = 0 ; NewCell = Cell).

% Display the Sudoku matrix
% Define the predicate to display the Sudoku matrix
display_sudoku(Matrix) :-
    maplist(writeln, Matrix),
    writeln('\n').


%%% ----------------------------------------------- %%%
%%% ------------ Solving Sudoku Table ------------- %%%
%%% ----------------------------------------------- %%%

% Solve the Sudoku puzzle
solve_sudoku(Rows) :- solve_cell(Rows, 1, 1).

solve_cell(Rows, 10, _) :- !, print_sudoku(Rows).
solve_cell(Rows, RowIndex, 10) :-
    !, NextRow is RowIndex + 1,
    solve_cell(Rows, NextRow, 1).
solve_cell(Rows, RowIndex, ColIndex) :-
    nth1(RowIndex, Rows, Row),
    nth1(ColIndex, Row, Cell),
    (   Cell \= 0
    ->  NextCol is ColIndex + 1,
        solve_cell(Rows, RowIndex, NextCol)
    ;   between(1, 9, Number),
        valid_placement(Number, Rows, RowIndex, ColIndex),
        replace(Row, ColIndex, Number, NewRow),
        replace(Rows, RowIndex, NewRow, NewRows),
        NextCol is ColIndex + 1,
        solve_cell(NewRows, RowIndex, NextCol)
    ).

% Verify if a number can be placed in a specific row, column, and block
valid_placement(Number, Rows, RowIndex, ColIndex) :-
    nth1(RowIndex, Rows, Row),
    no_duplicates(Row),
    extract_column(Rows, ColIndex, Column),
    no_duplicates(Column),
    BlockX is ((ColIndex - 1) // 3) + 1,
    BlockY is ((RowIndex - 1) // 3) + 1,
    extract_block(Rows, BlockX, BlockY, Block),
    no_duplicates(Block),
    \+ member(Number, Row),
    \+ member(Number, Column),
    \+ member(Number, Block).

% Simple print function to display the Sudoku grid
print_sudoku([]).
print_sudoku([Row|Rows]) :-
    print(Row), nl,
    print_sudoku(Rows).
