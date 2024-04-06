:- use_module(library(pce)).

% Define the main predicate for GUI setup and interaction
start_gui :-
    new(@main, dialog('Sudoku Solver')),
    send(@main, append, new(@sudoku_display, picture)),
    send(@main, append, button('Solve', message(@prolog, solve_sudoku_gui))),
    send(@main, append, button('Quit', message(@main, destroy))),
    send(@main, open),
    draw_empty_sudoku.


% Draw an empty Sudoku grid in the GUI
draw_empty_sudoku :-
    send(@sudoku_display, clear),
    XStart = 50,
    YStart = 50,
    CellSize = 40,
    XEnd is XStart + CellSize * 9,
    YEnd is YStart + CellSize * 9,
    new(P, picture),
    send(@sudoku_display, display, P, point(XStart, YStart)),
    send(P, size, size(XEnd, YEnd)),
    % Draw grid lines
    forall(between(0, 9, I),
           (   X1 is XStart + I * CellSize,
               Y1 is YStart + I * CellSize,
               send(P, display, new(_, line(X1, YStart, X1, YEnd))),
               send(P, display, new(_, line(XStart, Y1, XEnd, Y1)))
           )).

% Solve the Sudoku puzzle and display the solution in the GUI
solve_sudoku_gui :-
    % Retrieve the Sudoku grid from the GUI
    get_sudoku_grid(Grid),
    % Solve the Sudoku
    solve_sudoku(Grid).

% Helper predicate to get the Sudoku grid from the GUI
get_sudoku_grid(Grid) :-
    findall(Row, (between(1, 9, _), get_row(Row)), Grid).

% Helper predicate to get a row from the GUI
get_row(Row) :-
    findall(Cell, (between(1, 9, _), get_cell(Cell)), Row).

% Helper predicate to get a cell value from the GUI
get_cell(Cell) :-
    send(@sudoku_display, member, Cell), % Assuming the cells are named Cell1, Cell2, ..., Cell81
    send(Cell, instance_of, text),
    get(Cell, selection, Value),
    atom_number(Value, CellValue),
    CellValue >= 0, CellValue =< 9.

% Main predicate to run the GUI Sudoku solver
run_gui_sudoku :-
    start_gui,
    send(@main, wait_for),
    free(@main).

% Entry point for running the GUI Sudoku solver
:- run_gui_sudoku.
