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
    writeln('Creating a Sudoku puzzle is not currently available.').

process_choice(_) :-
    writeln('Invalid option. Please type "create" or "solve".'),
    start.

is_valid_puzzle(Puzzle) :-
    length(Puzzle, 9),
    maplist(length_(9), Puzzle).

length_(Length, List) :- length(List, Length).

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

replace([_|T], 1, X, [X|T]).
replace([H|T], I, X, [H|R]) :-
    I > 1, 
    NI is I - 1, 
    replace(T, NI, X, R).

% Simple print function to display the Sudoku grid
print_sudoku([]).
print_sudoku([Row|Rows]) :-
    print(Row), nl,
    print_sudoku(Rows).