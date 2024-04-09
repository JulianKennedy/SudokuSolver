% Attribution: This project was created with the help of GitHub copilot and some ChatGPT


% This functiostarts the program and prompts user to select a mode ("solve" or "create")
start :-
    writeln('Do you want to "create" or "solve" a Sudoku puzzle? (create/solve)'),
    read(UserChoice),
    process_choice(UserChoice).


% This starts the process of solving a Sudoku puzzle by prompting the user to input the puzzle
process_choice(solve) :-
    writeln('Please input the entire Sudoku puzzle as a nested list (list of lists), then press Enter:'),
    read(Puzzle),
    (   is_correct_sized_puzzle(Puzzle)
    ->  (   writeln('Solved puzzle below:'),
            solve_sudoku(Puzzle, SolvedSudoku)
        ->  writeln('YAY, the puzzle can be solved!'),
            display_sudoku(SolvedSudoku)
        ;   writeln('Could not solve the puzzle. Impossible puzzle.')
        )
    ;   writeln('Invalid puzzle format.'),
        writeln('Please ensure it\'s a nested list with 9 lists, each containing 9 elements.'),
        process_choice(solve)
    ).


% This starts the process of creating a Sudoku puzzle by generating a random puzzle, solving it, and then removing some elements
process_choice(create) :-
    choose_difficulty(Difficulty, Probability),
    repeat,
    create_sudoku_matrix(Sudoku),
    check_validity(Sudoku),
    solve_sudoku(Sudoku, SudokuSolution),
    remove_some_values_from_valid_sudoku_matrix(SudokuSolution, Probability, ProcessedSudoku),
    check_validity(ProcessedSudoku),
    writeln('Starting Sudoku board: \n'),
    display_sudoku(ProcessedSudoku),
    !. 


% This ensures valid mode
process_choice(_) :-
    writeln('Invalid option. Please type "create" or "solve".'),
    start.


% This checks that the puzzle is a 9x9 matrix
is_correct_sized_puzzle(Puzzle) :-
    length(Puzzle, 9),
    maplist(length_(9), Puzzle).


% Helper function for mapping length of a list since parameters need to be swapped.
length_(Length, List) :- length(List, Length).


% This prompts the user to select a difficulty level for the Sudoku puzzle
choose_difficulty(Difficulty, Probability) :-
    writeln('Choose difficulty level: '),
    writeln('easy'),
    writeln('medium'),
    writeln('hard'),
    read(DifficultyChoice),
    validate_difficulty(DifficultyChoice, Probability).


% This validates the difficulty level selected by the user and assigns a probability of removing elements from the Sudoku matrix
validate_difficulty(easy, 55).
validate_difficulty(medium, 65).
validate_difficulty(hard, 75).
validate_difficulty(_, 55) :-
    writeln('Invalid choice. Must be either "easy", "medium", or "hard".'),
    choose_difficulty(Difficulty, Probability).
    

% This creates a 9x9 Sudoku matrix with some random values
create_sudoku_matrix(Matrix) :-
    length(Matrix, 9),
    maplist(create_row_random, Matrix).


% This creates a single row with some random values
create_row_random(Row) :-
    length(Row, 9),
    maplist(maybe_assign_value, Row).


% This randomly assign a value between 1 and 9 with probability 10/81 to a cell
maybe_assign_value(Value) :-
    random(1, 82, Random),
    (Random =< 10 -> random(1, 10, Value) ; Value = 0).


% This checks the validity of all cells in the Sudoku matrix
check_validity(Sudoku) :-
    check_validity_cell(Sudoku, 1, 1).


% This checks the validity of a single cell in the Sudoku matrix then calls next cell
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


% This checks if a number can be placed in a specific row, column, and block, and has no duplicates 
check_placement(Number, Rows, RowIndex, ColIndex) :-
    nth1(RowIndex, Rows, Row),
    no_duplicates(Row),
    extract_column(Rows, ColIndex, Column),
    no_duplicates(Column),
    BlockX is ((ColIndex - 1) // 3) + 1,
    BlockY is ((RowIndex - 1) // 3) + 1,
    extract_block(Rows, BlockX, BlockY, Block),
    no_duplicates(Block).


% This checks if a list does not contain any duplicates (ignores 0)
no_duplicates([]).
no_duplicates([Head|Tail]) :- Head \= 0, member(Head, Tail), !, fail.
no_duplicates([_|Tail]) :-
    no_duplicates(Tail).


% This extracts a column from the Sudoku grid
extract_column([], _, []).
extract_column([Row|Matrix], ColIndex, [Item|Column]) :-
    nth1(ColIndex, Row, Item),
    extract_column(Matrix, ColIndex, Column).


% This extract a 3x3 block from the Sudoku grid
extract_block(Rows, BlockX, BlockY, Block) :-
    BlockStartRow is 1 + 3 * (BlockY - 1),
    BlockEndRow is 3 + 3 * (BlockY - 1),
    findall(Num, (between(BlockStartRow, BlockEndRow, RowIndex),
                  nth1(RowIndex, Rows, Row),
                  BlockStartCol is 1 + 3 * (BlockX - 1),
                  BlockEndCol is 3 + 3 * (BlockX - 1),
                  between(BlockStartCol, BlockEndCol, ColIndex),
                  nth1(ColIndex, Row, Num)), Block).


% This finds a potential solution for an unsolved Sudoku matrix and returns false if its impossible
solve_sudoku(Rows, SudokuSolution) :- solve_cell(Rows, 1, 1, SudokuSolution).


% This solves by cell and recursively calls next cell
solve_cell(Rows, 10, _, Rows).
solve_cell(Rows, RowIndex, 10, SudokuSolution) :-
    NextRow is RowIndex + 1,
    solve_cell(Rows, NextRow, 1, SudokuSolution).
solve_cell(Rows, RowIndex, ColIndex, SudokuSolution) :-
    nth1(RowIndex, Rows, Row),
    nth1(ColIndex, Row, Cell),
    (   Cell \= 0
    ->  NextCol is ColIndex + 1,
        solve_cell(Rows, RowIndex, NextCol, SudokuSolution)
    ;   between(1, 9, Number),
        valid_placement(Number, Rows, RowIndex, ColIndex),
        replace(Row, ColIndex, Number, NewRow),
        replace(Rows, RowIndex, NewRow, NewRows),
        NextCol is ColIndex + 1,
        solve_cell(NewRows, RowIndex, NextCol, SudokuSolution)
    ).


% This replaces the number at index `Index` in a list with a specific value `Value`
replace([_|Tail], 1, Value, [Value|Tail]).
replace([Head|Tail], Index, Value, [Head|Rest]) :-
    Index > 1, 
    NewIndex is Index - 1, 
    replace(Tail, NewIndex, Value, Rest).


% This randomly removes elements from the Sudoku matrix based on a probability set by difficulty
remove_some_values_from_valid_sudoku_matrix([], _, []).
remove_some_values_from_valid_sudoku_matrix([Row|Rows], Percentage, [ProcessedRow|ProcessedRows]) :-
    remove_values_from_row(Row, Percentage, ProcessedRow),
    remove_some_values_from_valid_sudoku_matrix(Rows, Percentage, ProcessedRows).


% This is a function to randomly remove elements from a row based on a given percentage set by difficulty
remove_values_from_row([], _, []).
remove_values_from_row([Cell|Cells], Percentage, [ProcessedCell|ProcessedCells]) :-
    maybe_remove(Cell, Percentage, ProcessedCell),
    remove_values_from_row(Cells, Percentage, ProcessedCells).


% This takes in a single cell to randomly remove a value based on a given probability set by difficulty
maybe_remove(Cell, Percentage, NewCell) :-
    random(1, 101, Random),
    (Random =< Percentage -> NewCell = 0 ; NewCell = Cell).


% This is a function that prints out a Sudoku matrix
display_sudoku(Matrix) :-
    maplist(writeln, Matrix),
    writeln('\n').


% This verifies if a number can be placed in a specific row, column, and block, and has no duplicates. This is for solving while check_placement is for validating.
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
