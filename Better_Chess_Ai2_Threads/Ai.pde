import java.util.*;
import java.util.stream.Collectors;
import java.util.concurrent.*;

int maxDepth = 5;
EnumMap<piece, Integer> values = new EnumMap(piece.class);

void aiMove(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved, boolean whiteToMove){
  int start = millis();
  boolean[] whiteCastling = whiteCanCastle.clone();
  boolean[] blackCastling = blackCanCastle.clone();
  BoardPos currentBoard = new BoardPos(board, whiteCastling, blackCastling, pawnMoved);
  
  //generate all moves
  float max = -1000000;
  List<BoardPos> moves = generateMoves(currentBoard, whiteToMove);
  
  //evaluate all moves with multithreading
  ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
  List<Future<BoardPos>> results = new ArrayList();
  for(BoardPos move : moves){
    results.add(executor.submit(new Ai(move, whiteToMove)));
  }
  
  //find which moves are best, all moves which share the same highest score will be grouped and have one picked at random
  ArrayList<BoardPos> bestMoves = new ArrayList();
  for (Future<BoardPos> f : results) {
    try{
      BoardPos move = f.get();
      float score = move.eval;
      //System.out.println(score);
      if(score - max > 0.001) {
        max = score;
        bestMoves.clear();
        bestMoves.add(move);
      }
      else if(Math.abs(score - max) < 0.001) bestMoves.add(move);
    }
    catch (Exception e){
      System.out.println(e);
      //e.printStackTrace();
    }
  }
  executor.shutdown();
  
  //perform one of the best move
  if(!bestMoves.isEmpty()){
    BoardPos bestMove = bestMoves.get(int(random(bestMoves.size())));
    globalBoard = bestMove.board;
    globalWhiteCanCastle = bestMove.whiteCanCastle;
    globalBlackCanCastle = bestMove.blackCanCastle;
    globalPawnMoved = bestMove.pawnMoved;
  }
  
  int end = millis();
  System.out.println(end-start); //prints how many milliseconds the ai move took to make
}

class Ai implements Callable<BoardPos>{
  
  BoardPos sboardPos; boolean swhiteToMove;
  
  public Ai(BoardPos boardPos, boolean whiteToMove){
    sboardPos = boardPos; 
    swhiteToMove = whiteToMove; 
  }
  
  BoardPos call(){
    sboardPos.eval = -negamax(maxDepth-1, sboardPos, !swhiteToMove, -1000000, 1000000);
    return sboardPos;
  }
  
  //https://www.chessprogramming.org/Alpha-Beta
  float negamax(int depth, BoardPos boardPos, boolean whiteToMove, float alpha, float beta){
    if (depth == 0) return boardEval(boardPos, whiteToMove, depth);
    List<BoardPos> moves = generateMoves(boardPos, whiteToMove);
    if(moves.isEmpty()) return boardEval(boardPos, whiteToMove, depth);
    moves = organizeMoves(moves, whiteToMove);
    for(BoardPos move : moves){
      float score = -negamax(depth-1, move, !whiteToMove, -beta, -alpha);
      if(score >= beta) return beta;
      if(score > alpha) alpha = score;
    }
    return alpha;
  }
}

/**
 * Generates a list of all future board positions that can be reached after one move
 * @param boardPos the starting board position
 * @param whiteToMove true if it is whites turn, false for black
 * @return a list of future board positions
**/
ArrayList<BoardPos> generateMoves(BoardPos boardPos, boolean whiteToMove){
  piece[][] board = boardPos.board;
  boolean[] whiteCanCastle = boardPos.whiteCanCastle;
  boolean[] blackCanCastle = boardPos.blackCanCastle;
  int pawnMoved = boardPos.pawnMoved;
  ArrayList<BoardPos> moves = new ArrayList();
  boolean[][] legalMoves = new boolean[BOARD_WIDTH][BOARD_HEIGHT];
  for (int i = 0; i < BOARD_WIDTH; i++) {
    for (int j = 0; j < BOARD_HEIGHT; j++) {
      if((whiteToMove && isWhite(i, j, board)) || (!whiteToMove && isBlack(i, j, board))){ //find all pieces to move
        findLegalMoves(i, j, board, legalMoves, whiteCanCastle, blackCanCastle, pawnMoved);
        
        for (int x = 0; x < BOARD_WIDTH; x++) {
          for (int y = 0; y < BOARD_HEIGHT; y++) { //find all legal moves for the piece
            if(legalMoves[x][y]){
              piece[][] newBoard = duplicateBoard(board);
              boolean[] whiteCastling = whiteCanCastle.clone();
              boolean[] blackCastling = blackCanCastle.clone();
              int newPawnMoved = movePiece(i, j, x, y, newBoard, whiteCastling, blackCastling);
              BoardPos nextBoard = new BoardPos(newBoard, whiteCastling, blackCastling, newPawnMoved);
              if(!aiPromotion(nextBoard, whiteToMove, moves, x, y)) moves.add(nextBoard); //add move to list
            }
          }
        }
        
        clearLegalMoves(legalMoves);
      }
    }
  }
  return moves;
}

//Returns a copy of the board
piece[][] duplicateBoard(piece[][] board){
  piece[][] newBoard = new piece[BOARD_WIDTH][BOARD_HEIGHT];
  for (int i = 0; i < BOARD_WIDTH; i++) {
    newBoard[i] = board[i].clone();
  }
  return newBoard;
}

/**
 * If a pawn is pushed to the end of the board consider all options for what to promote it to and add the options to the moves list
 * @param boardPos the board position being considered
 * @param whiteToMove true if it is whites turn, false for black
 * @param moves the list of future moves being generated
 * @param x the x board coordinate of the piece that was moved
 * @param y the y board coordinate of the piece that was moved
 * @return true if a pawn was promoted and false otherwise
**/
boolean aiPromotion(BoardPos boardPos, boolean whiteToMove, List<BoardPos> moves, int x, int y){
  piece[][] board = boardPos.board;
  if(whiteToMove){
    if(y == 7 && board[x][y] == piece.WHITE_PAWN){
      piece[][] newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.WHITE_QUEEN;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.WHITE_ROOK;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.WHITE_BISHOP;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.WHITE_KNIGHT;
      moves.add(new BoardPos(newBoard, boardPos));
      return true;
    }
  }
  else{
    if(y == 0 && board[x][y] == piece.BLACK_PAWN){
      piece[][] newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.BLACK_QUEEN;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.BLACK_ROOK;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.BLACK_BISHOP;
      moves.add(new BoardPos(newBoard, boardPos));
      newBoard = duplicateBoard(board);
      newBoard[x][y] = piece.BLACK_KNIGHT;
      moves.add(new BoardPos(newBoard, boardPos));
      return true;
    }
  }
  return false;
}

/**
 * Evaluates the current position of the board to determine which side is doing better or worse
 * @param boardPos the board position being evaluated
 * @param whiteToMove true if it is whites turn, false for black
 * @param depth the current depth of the move being considered (used so that checkmates found further down the move tree are less important than ones found further up)
 * @return the evaluation of the board
**/
float boardEval(BoardPos boardPos, boolean whiteToMove, int depth){
  piece[][] board = boardPos.board;
  float eval = 0;
  for (int i = 0; i < BOARD_WIDTH; i++) { 
    for (int j = 0; j < BOARD_HEIGHT; j++) {
      switch(board[i][j]){
        case WHITE_PAWN:
        eval += map(j, 1, 7, 1, 3);
        if(j == 1 && (i == 3 || i == 4)) eval -= 0.5; //encourage pushing the center pawns first
        break;
        
        case WHITE_BISHOP:
        if(i == j || i == 7-j) eval += 0.3; //bishops on the long diagonal are strongest
        case WHITE_KNIGHT:
        eval+=3;
        break;
        
        case WHITE_ROOK:
        eval+=5;
        break;
        
        case WHITE_QUEEN:
        eval+=9;
        break;
        
        case WHITE_KING:
        if(j == 0 && (i == 2 || i == 6)) eval += 0.5; //encourage the king to castle
        break;
        
        case BLACK_PAWN:
        eval -= map(j, 6, 0, 1, 3);
        if(j == 6 && (i == 3 || i == 4)) eval += 0.5; //encourage pushing the center pawns first
        break;
        
        case BLACK_BISHOP:
        if(i == j || i == 7-j) eval -= 0.3; //bishops on the long diagonal are strongest
        case BLACK_KNIGHT:
        eval-=3;
        break;
        
        case BLACK_ROOK:
        eval-=5;
        break;
        
        case BLACK_QUEEN:
        eval-=9;
        break;
        
        case BLACK_KING:
        if(j == 7 && (i == 2 || i == 6)) eval -= 0.5; //encourage the king to castle
        break;
        
        default:
      }
    }
  }
  
  if(whiteToMove){
    if(whiteInCheck(board)){
      if(whiteNoLegalMoves(boardPos.board, boardPos.whiteCanCastle, boardPos.blackCanCastle, boardPos.pawnMoved)) eval-=map(depth, 0, maxDepth, 15, 50); //checkmate
      else eval = 0; //stalemate
    }
  }
  else{
    if(blackInCheck(board)){
      if(blackNoLegalMoves(boardPos.board, boardPos.whiteCanCastle, boardPos.blackCanCastle, boardPos.pawnMoved)) eval+=map(depth, 0, maxDepth, 15, 50); //checkmate
      else eval = 0; //stalemate
    }
    return -eval; //return negative eval for black
  }
  return eval;
}

/**
 * Organizes the moves in the given list such that they are sorted by the evaluation
 * This is done to speed up the alpha-beta pruning for the negamax algorithm
 * @param moves the list of moves to be ordered
 * @param whiteToMove true if it is whites turn, false for black
 * @return the same list of moves but now ordered
**/
List<BoardPos> organizeMoves(List<BoardPos> moves, boolean whiteToMove){
  HashMap<BoardPos, Float> evals = new HashMap();
  for(BoardPos move : moves){
    evals.put(move, quickEval(move, whiteToMove)); //map each position to its evalutaion
  }
  ArrayList<Map.Entry<BoardPos, Float>> list = new ArrayList(evals.entrySet()); //sort the map by evaluation
  list.sort(Map.Entry.comparingByValue(Collections.reverseOrder()));
  
  return list.stream().map(HashMap.Entry::getKey).collect(Collectors.toList());
}

/**
 * Performs a quick evaluation of the board position to give a rough ordering used in organizeMoves()
 * This does not consider check, checkmate or stalemate in the evaluation
 * @param boardPos the board position being evaluated
 * @param whiteToMove true if it is whites turn, false for black
 * @return the rough evaluation of the board
**/
Float quickEval(BoardPos boardPos, boolean whiteToMove){
  piece[][] board = boardPos.board;
  float eval = 0;
  for (int i = 0; i < BOARD_WIDTH; i++) { 
    for (int j = 0; j < BOARD_HEIGHT; j++) {
      eval += values.get(board[i][j]);
    }
  }
  
  if(whiteToMove) return eval;
  return -eval;
} //<>//

//Used to store the current position of a board including whether white and black can castle and which pawn moved last
class BoardPos{
  piece[][] board;
  boolean[] whiteCanCastle;
  boolean[] blackCanCastle;
  int pawnMoved;
  float eval;
  
  public BoardPos(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
    this.board = board;
    this.whiteCanCastle = whiteCanCastle;
    this.blackCanCastle = blackCanCastle;
    this.pawnMoved = pawnMoved;
  }
  
  public BoardPos(piece[][] board, BoardPos copying){ //create a copy of the BoardPos given with an updated board (used for promotion)
    this.board = board;
    whiteCanCastle = copying.whiteCanCastle;
    blackCanCastle = copying.blackCanCastle;
    pawnMoved = copying.pawnMoved;
  }
}
