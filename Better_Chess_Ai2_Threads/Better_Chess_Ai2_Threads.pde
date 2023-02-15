final int WINDOW_WIDTH = 900, WINDOW_HEIGHT = 900; //change this to your needs
final int BOARD_WIDTH = 8, BOARD_HEIGHT = 8; //dont change this

boolean aiPlaysWhite = false; //----------------------------------------------------------------------

enum piece{
  BLACK_PAWN, BLACK_KNIGHT, BLACK_BISHOP, BLACK_ROOK, BLACK_QUEEN, BLACK_KING,
  WHITE_PAWN, WHITE_KNIGHT, WHITE_BISHOP, WHITE_ROOK, WHITE_QUEEN, WHITE_KING,
  EMPTY
}
PImage white_pawn;
PImage white_rook;
PImage white_knight;
PImage white_bishop;
PImage white_queen;
PImage white_king;

PImage black_pawn;
PImage black_rook;
PImage black_knight;
PImage black_bishop;
PImage black_queen;
PImage black_king;


piece[][] globalBoard;
boolean[][] globalLegalMoves;

int squareSize;
int chosenX = -1, chosenY = -1;

boolean whiteTurn = true;
boolean stalemate = false;
boolean whiteWins = false;
boolean blackWins = false;
boolean whitePromoting = false;
boolean blackPromoting = false;
boolean whiteInCheck = false;
boolean blackInCheck = false;

boolean[] globalWhiteCanCastle = new boolean[] {true, true, true}; //Rook has moved, then king, then rook
boolean[] globalBlackCanCastle = new boolean[] {true, true, true};

int globalPawnMoved = -1; //Used for en passant
int promotingX = -1; //Used for promoting pawns

int[][] knightDirections = {{-2,-1}, {-2,1}, {2,-1}, {2,1}, {-1,-2}, {-1,2}, {1,-2}, {1,2}};
int[][] bishopDirections = {{-1,-1}, {-1,1}, {1,-1}, {1,1}}; 
int[][] rookDirections = {{-1,0}, {1,0}, {0,-1}, {0,1}}; 


void settings(){
  size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

void setup() {
  ellipseMode(CENTER);
  textAlign(CENTER, CENTER);

  loadImages();

  resetBoard();
  
  squareSize = min(WINDOW_WIDTH, WINDOW_HEIGHT) / 9;
  
  if(aiPlaysWhite) {
    aiMove(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved, whiteTurn);
    whiteTurn = !whiteTurn;
  }
  
  values.put(piece.WHITE_PAWN, 1); //used for evaluating the board
  values.put(piece.WHITE_KNIGHT, 3);
  values.put(piece.WHITE_BISHOP, 3);
  values.put(piece.WHITE_ROOK, 5);
  values.put(piece.WHITE_QUEEN, 9);
  values.put(piece.WHITE_KING, 0);
  values.put(piece.BLACK_PAWN, -1);
  values.put(piece.BLACK_KNIGHT, -3);
  values.put(piece.BLACK_BISHOP, -3);
  values.put(piece.BLACK_ROOK, -5);
  values.put(piece.BLACK_QUEEN, -9);
  values.put(piece.BLACK_KING, 0);
  values.put(piece.EMPTY, 0);
}

void loadImages(){
  white_pawn = loadImage("white_pawn.png");
  white_rook = loadImage("white_rook.png");
  white_knight = loadImage("white_knight.png");
  white_bishop = loadImage("white_bishop.png");
  white_queen = loadImage("white_queen.png");
  white_king = loadImage("white_king.png");

  black_pawn = loadImage("black_pawn.png");
  black_rook = loadImage("black_rook.png");
  black_knight = loadImage("black_knight.png");
  black_bishop = loadImage("black_bishop.png");
  black_queen = loadImage("black_queen.png");
  black_king = loadImage("black_king.png");
}

void resetBoard(){
  globalBoard = new piece[BOARD_WIDTH][BOARD_HEIGHT];
  globalLegalMoves = new boolean[BOARD_WIDTH][BOARD_HEIGHT];
  
  for (int i = 0; i < BOARD_WIDTH; i++) {
    for (int j = 0; j < BOARD_HEIGHT; j++) {
      globalBoard[i][j] = piece.EMPTY;
    }
  }
  
  for (int i = 0; i < BOARD_WIDTH; i++) {
    globalBoard[i][1] = piece.WHITE_PAWN;
    globalBoard[i][6] = piece.BLACK_PAWN;
  }

  globalBoard[0][0] = piece.WHITE_ROOK;
  globalBoard[7][0] = piece.WHITE_ROOK;
  globalBoard[1][0] = piece.WHITE_KNIGHT;
  globalBoard[6][0] = piece.WHITE_KNIGHT;
  globalBoard[2][0] = piece.WHITE_BISHOP;
  globalBoard[5][0] = piece.WHITE_BISHOP;
  globalBoard[3][0] = piece.WHITE_QUEEN;
  globalBoard[4][0] = piece.WHITE_KING;

  globalBoard[0][7] = piece.BLACK_ROOK;
  globalBoard[7][7] = piece.BLACK_ROOK;
  globalBoard[1][7] = piece.BLACK_KNIGHT;
  globalBoard[6][7] = piece.BLACK_KNIGHT;
  globalBoard[2][7] = piece.BLACK_BISHOP;
  globalBoard[5][7] = piece.BLACK_BISHOP;
  globalBoard[3][7] = piece.BLACK_QUEEN;
  globalBoard[4][7] = piece.BLACK_KING;
  
  chosenX = -1; chosenY = -1;
  
  whiteTurn = true;
  stalemate = false;
  whiteWins = false;
  blackWins = false;
  whitePromoting = false;
  blackPromoting = false;
  whiteInCheck = false;
  blackInCheck = false;
  
  globalWhiteCanCastle = new boolean[] {true, true, true};
  globalBlackCanCastle = new boolean[] {true, true, true};
  
  globalPawnMoved = -1;
  promotingX = -1;
}

void draw() {
  background(100);
  translate(squareSize/2, squareSize/2);

  for (int i = 0; i < BOARD_WIDTH; i++) { 
    for (int j = 0; j < BOARD_HEIGHT; j++) {
      if ((i + j) % 2 == 0) { //draw the board
        fill(118, 150, 86);
      } else {
        fill(238, 238, 210);
      }
      if (i == chosenX && j == chosenY) { //highlight chosen square
        fill(255, 100, 100);
      }
      
      int xcoord = i*squareSize, ycoord = (7 - j)*squareSize;
      
      square(xcoord, ycoord, squareSize);

      switch(globalBoard[i][j]) { //draw the pieces
        case WHITE_PAWN:
        image(white_pawn, xcoord, ycoord, squareSize, squareSize);
        break;

        case WHITE_ROOK:
        image(white_rook, xcoord, ycoord, squareSize, squareSize);
        break;

        case WHITE_KNIGHT:
        image(white_knight, xcoord, ycoord, squareSize, squareSize);
        break;

        case WHITE_BISHOP:
        image(white_bishop, xcoord, ycoord, squareSize, squareSize);
        break;

        case WHITE_QUEEN:
        image(white_queen, xcoord, ycoord, squareSize, squareSize);
        break;

        case WHITE_KING:
        image(white_king, xcoord, ycoord, squareSize, squareSize);
        break;
        
        case BLACK_PAWN:
        image(black_pawn, xcoord, ycoord, squareSize, squareSize);
        break;

        case BLACK_ROOK:
        image(black_rook, xcoord, ycoord, squareSize, squareSize);
        break;

        case BLACK_KNIGHT:
        image(black_knight, xcoord, ycoord, squareSize, squareSize);
        break;

        case BLACK_BISHOP:
        image(black_bishop, xcoord, ycoord, squareSize, squareSize);
        break;

        case BLACK_QUEEN:
        image(black_queen, xcoord, ycoord, squareSize, squareSize);
        break;

        case BLACK_KING:
        image(black_king, xcoord, ycoord, squareSize, squareSize);
        break;
        
        default:
        break;
      }

      if (chosenX > -1 && globalLegalMoves[i][j]) { //show legal moves
        fill(100);
        circle(xcoord + squareSize/2, ycoord + squareSize/2, squareSize/3);
      }
    }
  }

  fill(255);
  if (whitePromoting) { //show if pawn is promoting
    rect(promotingX * squareSize, 0, squareSize, 4*squareSize);
    image(white_queen, promotingX * squareSize, 0, squareSize, squareSize);
    image(white_rook, promotingX * squareSize, squareSize, squareSize, squareSize);
    image(white_bishop, promotingX * squareSize, 2*squareSize, squareSize, squareSize);
    image(white_knight, promotingX * squareSize, 3*squareSize, squareSize, squareSize);
  }
  if (blackPromoting) {
    rect(promotingX * squareSize, 4*squareSize, squareSize, 4*squareSize);
    image(black_queen, promotingX * squareSize, 4*squareSize, squareSize, squareSize);
    image(black_rook, promotingX * squareSize, 5*squareSize, squareSize, squareSize);
    image(black_bishop, promotingX * squareSize, 6*squareSize, squareSize, squareSize);
    image(black_knight, promotingX * squareSize, 7*squareSize, squareSize, squareSize);
  }


  fill(0);
  textSize(squareSize/3); //draw coordinates of the board
  text("A", squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("B", 3*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("C", 5*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("D", 7*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("E", 9*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("F", 11*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("G", 13*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);
  text("H", 15*squareSize/2, squareSize*BOARD_HEIGHT + squareSize/4);

  text("8", -squareSize/4, squareSize/2);
  text("7", -squareSize/4, 3*squareSize/2);
  text("6", -squareSize/4, 5*squareSize/2);
  text("5", -squareSize/4, 7*squareSize/2);
  text("4", -squareSize/4, 9*squareSize/2);
  text("3", -squareSize/4, 11*squareSize/2);
  text("2", -squareSize/4, 13*squareSize/2);
  text("1", -squareSize/4, 15*squareSize/2);


  if (whiteInCheck && !blackWins) { //show if in check
    fill(255);
    textSize(squareSize/2);
    text("White In Check", WINDOW_WIDTH/2-squareSize/2, -squareSize/4);
  }
  else if (blackInCheck && !whiteWins) {
    fill(0);
    textSize(squareSize/2);
    text("Black In Check", WINDOW_WIDTH/2-squareSize/2, -squareSize/4);
  }

  if (stalemate) {
    fill(255, 0, 0);
    textSize(squareSize/2);
    text("Stalemate!", WINDOW_WIDTH/2-squareSize/2, -squareSize/4);
  } else if (blackWins) {
    fill(0);
    textSize(squareSize/2);
    text("Black Wins by Checkmate", WINDOW_WIDTH/2-squareSize/2, -squareSize/4);
  } else if (whiteWins) {
    fill(255);
    textSize(squareSize/2);
    text("White Wins by Checkmate", WINDOW_WIDTH/2-squareSize/2, -squareSize/4);
  }
}


void keyReleased() {
  if (whiteWins || blackWins || stalemate) { //restart the game
    resetBoard();
  }
}

//-----------------------------------------------------------------------------
//left clicking a piece should highlight the piece and show its available moves
//right clicking should remove the highlight
//left clicking while a piece is highlighted should move the piece to the chosen square (if available)
//left clicking an empty square should also remove the highlight


//Returns true if the mouse is over the board
boolean mouseOnBoard(){
  return mouseX > squareSize/2 && mouseX < WINDOW_WIDTH - squareSize/2
      && mouseY > squareSize/2 && mouseY < WINDOW_HEIGHT - squareSize/2;
}


void mousePressed() {
  if(mouseButton == LEFT && mouseOnBoard()){
    if(whitePromoting){
      int movingX = (mouseX - squareSize/2) / squareSize;
      int movingY = 7 - ((mouseY - squareSize/2) / squareSize);
      if(movingX == promotingX){
        switch(movingY){
          case 7:
          globalBoard[promotingX][7] = piece.WHITE_QUEEN;
          break;
          
          case 6:
          globalBoard[promotingX][7] = piece.WHITE_ROOK;
          break;
          
          case 5:
          globalBoard[promotingX][7] = piece.WHITE_BISHOP;
          break;
          
          case 4:
          globalBoard[promotingX][7] = piece.WHITE_KNIGHT;
          break;
          
          default:
          return;
        }
        whitePromoting = false;
        if(blackInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
          whiteWins = true;
          return;
        }
        stalemate = blackNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
        blackInCheck = blackInCheck(globalBoard);
        
        whiteTurn = !whiteTurn;
        aiMove(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved, whiteTurn);
        
        if(whiteInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
          blackWins = true;
          clearLegalMoves(globalLegalMoves);
          return;
        }
        stalemate = whiteNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
        
        whiteTurn = !whiteTurn;
      }
    }
    else if(blackPromoting){
      int movingX = (mouseX - squareSize/2) / squareSize;
      int movingY = 7 - ((mouseY - squareSize/2) / squareSize);
      if(movingX == promotingX){
        switch(movingY){
          case 3:
          globalBoard[promotingX][0] = piece.BLACK_QUEEN;
          break;
          
          case 2:
          globalBoard[promotingX][0] = piece.BLACK_ROOK;
          break;
          
          case 1:
          globalBoard[promotingX][0] = piece.BLACK_BISHOP;
          break;
          
          case 0:
          globalBoard[promotingX][0] = piece.BLACK_KNIGHT;
          break;
          
          default:
          return;
        }
        blackPromoting = false;
        if(whiteInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
          blackWins = true;
          return;
        }
        stalemate = whiteNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
        whiteInCheck = whiteInCheck(globalBoard);
        whiteTurn = true;
        
        whiteTurn = !whiteTurn;
        aiMove(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved, whiteTurn);
        
        if(blackInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
          whiteWins = true;
          clearLegalMoves(globalLegalMoves);
          return;
        }
        stalemate = blackNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
        
        whiteTurn = !whiteTurn;
      }
    }
    else{
      if(chosenX == -1){ //highlight piece
        chosenX = (mouseX - squareSize/2) / squareSize;
        chosenY = 7 - ((mouseY - squareSize/2) / squareSize);
        if(globalBoard[chosenX][chosenY] != piece.EMPTY && isWhite(chosenX, chosenY, globalBoard) == whiteTurn){
          findLegalMoves(chosenX, chosenY, globalBoard, globalLegalMoves, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
        }
      }
      else{ //move highlighted piece
        int movingX = (mouseX - squareSize/2) / squareSize;
        int movingY = 7 - ((mouseY - squareSize/2) / squareSize);
        if(globalLegalMoves[movingX][movingY]){
          globalPawnMoved = movePiece(chosenX, chosenY, movingX, movingY, globalBoard, globalWhiteCanCastle,globalBlackCanCastle);
          
          if(globalBoard[movingX][movingY] == piece.WHITE_PAWN && movingY == 7) { //check for promoting
            whitePromoting = true;
            promotingX = movingX;
            clearLegalMoves(globalLegalMoves);
            return;
          }
          if(globalBoard[movingX][movingY] == piece.BLACK_PAWN && movingY == 0) {
            blackPromoting = true;
            promotingX = movingX;
            clearLegalMoves(globalLegalMoves);
            return;
          }
          
          if(whiteTurn){
            if(blackInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
              whiteWins = true;
              clearLegalMoves(globalLegalMoves);
              return;
            }
            stalemate = blackNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
          }
          else{
            if(whiteInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
              blackWins = true;
              clearLegalMoves(globalLegalMoves);
              return;
            }
            stalemate = whiteNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
          }
          
          
          
          whiteTurn = !whiteTurn;
          aiMove(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved, whiteTurn);
          if(whiteTurn){
            if(blackInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
              whiteWins = true;
              clearLegalMoves(globalLegalMoves);
              return;
            }
            stalemate = blackNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
          }
          else{
            if(whiteInCheckmate(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved)) {
              blackWins = true;
              clearLegalMoves(globalLegalMoves);
              return;
            }
            stalemate = whiteNoLegalMoves(globalBoard, globalWhiteCanCastle, globalBlackCanCastle, globalPawnMoved);
          }
          whiteTurn = !whiteTurn;
        }
        
        whiteInCheck = whiteInCheck(globalBoard);
        blackInCheck = blackInCheck(globalBoard);
        
        clearLegalMoves(globalLegalMoves);
      }
    }
  }
  else if (mouseButton == RIGHT){ //remove highlighting
    clearLegalMoves(globalLegalMoves);
  }
}

/**
 * Moves the piece from the given coordinates to the other given coordinates on the given board and implements en passent and castling when necessary.
 * Also updates the castling conditions and returns which pawn is moved when applicable for en passent.
 * Note that this function does not check whether a move is legal as this should be completed using the findLegalMoves() function.
 * @param fromX the x board coordinate of the piece to be moved
 * @param fromY the y board coordinate of the piece to be moved
 * @param toX the x board coordinate of where to move the piece
 * @param toY the y board coordinate of where to move the piece
 * @param board the board on which the piece is moved (needed for the ai)
 * @param whiteCanCastle a boolean array representing if the white left-rook, king and right-rook has already moved
 * @param blackCanCastle a boolean array representing if the black left-rook, king and right-rook has already moved
 * @return the x board coordinate of the pawn that is moved when appliacable or -1 otherwise
**/
int movePiece(int fromX, int fromY, int toX, int toY, piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle){
  if(board[fromX][fromY] == piece.WHITE_PAWN && abs(fromX-toX) == 1 && board[toX][toY] == piece.EMPTY) board[toX][toY-1] = piece.EMPTY; //check for en passent
  else if(board[fromX][fromY] == piece.BLACK_PAWN && abs(fromX-toX) == 1 && board[toX][toY] == piece.EMPTY) board[toX][toY+1] = piece.EMPTY;
  
  board[toX][toY] = board[fromX][fromY]; //moves the piece
  board[fromX][fromY] = piece.EMPTY;
  
  if(board[toX][toY] == piece.WHITE_KING && toX == 2 && fromX == 4) { //check for castling
    board[0][0] = piece.EMPTY;
    board[3][0] = piece.WHITE_ROOK; 
  }
  else if(board[toX][toY] == piece.WHITE_KING && toX == 6 && fromX == 4) {
    board[7][0] = piece.EMPTY;
    board[5][0] = piece.WHITE_ROOK; 
  }
  else if(board[toX][toY] == piece.BLACK_KING && toX == 2 && fromX == 4) {
    board[0][7] = piece.EMPTY;
    board[3][7] = piece.BLACK_ROOK; 
  }
  else if(board[toX][toY] == piece.BLACK_KING && toX == 6 && fromX == 4) {
    board[7][7] = piece.EMPTY;
    board[5][7] = piece.BLACK_ROOK; 
  }
  
  if(whiteCanCastle[0]) whiteCanCastle[0] = board[0][0] == piece.WHITE_ROOK; //check for castling capabilities
  if(whiteCanCastle[1]) whiteCanCastle[1] = board[4][0] == piece.WHITE_KING;
  if(whiteCanCastle[2]) whiteCanCastle[2] = board[7][0] == piece.WHITE_ROOK;
  if(blackCanCastle[0]) blackCanCastle[0] = board[0][7] == piece.BLACK_ROOK;
  if(blackCanCastle[1]) blackCanCastle[1] = board[4][7] == piece.BLACK_KING;
  if(blackCanCastle[2]) blackCanCastle[2] = board[7][7] == piece.BLACK_ROOK;
  
  int pawnMoved = -1; //check for en passent capability
  if(board[toX][toY] == piece.WHITE_PAWN && fromY == 1 && toY == 3) pawnMoved = toX;
  else if(board[toX][toY] == piece.BLACK_PAWN && fromY == 6 && toY == 4) pawnMoved = toX;
  
  return pawnMoved;
}

boolean isBlack(int x, int y, piece[][] board){ //returns true when the piece at x,y is black
  return board[x][y] == piece.BLACK_PAWN || board[x][y] == piece.BLACK_KNIGHT || board[x][y] == piece.BLACK_BISHOP
      || board[x][y] == piece.BLACK_ROOK || board[x][y] == piece.BLACK_QUEEN || board[x][y] == piece.BLACK_KING;
}
boolean isWhite(int x, int y, piece[][] board){ //returns true when the piece at x,y is white
  return board[x][y] == piece.WHITE_PAWN || board[x][y] == piece.WHITE_KNIGHT || board[x][y] == piece.WHITE_BISHOP
      || board[x][y] == piece.WHITE_ROOK || board[x][y] == piece.WHITE_QUEEN || board[x][y] == piece.WHITE_KING;
}
boolean isEnemy(int x1, int y1, int x2, int y2, piece[][] board){ //returns true when the piece at x1,y1 is a different colour to the piece at x2,y2
  return (isWhite(x1, y1, board) && isBlack(x2, y2, board)) || (isBlack(x1, y1, board) && isWhite(x2, y2, board));
}
boolean blackOrEmpty(int x, int y, piece[][] board){ //returns true when the piece at x,y is black or there is no piece
  return isBlack(x, y, board) || board[x][y] == piece.EMPTY;
}
boolean whiteOrEmpty(int x, int y, piece[][] board){ //returns true when the piece at x,y is white or there is no piece
  return isWhite(x, y, board) || board[x][y] == piece.EMPTY;
}
boolean enemyOrEmpty(int x1, int y1, int x2, int y2, piece[][] board){ //returns true when the piece at x1,y1 is a different colour to the piece at x2,y2 or if x2,y2 has no piece
  return isEnemy(x1, y1, x2, y2, board) || board[x2][y2] == piece.EMPTY;
}

boolean inbounds(int x, int y){ //returns true if x,y is a legal board coordinate
  return x >= 0 && x < BOARD_WIDTH && y >= 0 && y < BOARD_HEIGHT;
}

//Fills the boolean array legalMoves with false
void clearLegalMoves(boolean[][] legalMoves){
  chosenX = -1;
  chosenY = -1;
  for(int i = 0 ; i < BOARD_WIDTH; i++){
    for(int j = 0 ; j < BOARD_HEIGHT; j++){
      legalMoves[i][j] = false;
    }
  }
}

/**
 * Finds which squares the piece at the given coordinates can move to on the given board and sets that position in the legalMoves array to be true.
 * This function also considers castling and en passent using the extra inputs.
 * @param pieceX the x board coordinate of the piece to be moved
 * @param pieceY the y board coordinate of the piece to be moved
 * @param board the board on which the piece is moved (needed for the ai)
 * @param legalMoves the 2D boolean array which represents which moves are legal
 * @param whiteCanCastle a boolean array representing if the white left-rook, king and right-rook has already moved
 * @param blackCanCastle a boolean array representing if the black left-rook, king and right-rook has already moved
 * @param pawnMoved the x board coordinate of the last pawn moved
**/
void findLegalMoves(int pieceX, int pieceY, piece[][] board, boolean[][] legalMoves, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
  int count;
  switch(board[pieceX][pieceY]){
    case WHITE_PAWN:
    if(inbounds(pieceX, pieceY+1)) legalMoves[pieceX][pieceY+1] = board[pieceX][pieceY+1] == piece.EMPTY; //move forward one square
    if(inbounds(pieceX, pieceY+2)) legalMoves[pieceX][pieceY+2] = pieceY == 1 && board[pieceX][pieceY+1] == piece.EMPTY && board[pieceX][pieceY+2] == piece.EMPTY; //two squares on first turn
    if(inbounds(pieceX-1, pieceY+1)) legalMoves[pieceX-1][pieceY+1] = isBlack(pieceX-1, pieceY+1, board); //take diagonally
    if(inbounds(pieceX+1, pieceY+1)) legalMoves[pieceX+1][pieceY+1] = isBlack(pieceX+1, pieceY+1, board);
    if(inbounds(pieceX-1, pieceY+1) && pawnMoved == pieceX-1 && pieceY == 4) legalMoves[pieceX-1][pieceY+1] = true;//en passent
    if(inbounds(pieceX+1, pieceY+1) && pawnMoved == pieceX+1 && pieceY == 4) legalMoves[pieceX+1][pieceY+1] = true;
    break;
    
    case BLACK_PAWN:
    if(inbounds(pieceX, pieceY-1)) legalMoves[pieceX][pieceY-1] = board[pieceX][pieceY-1] == piece.EMPTY; //move forward one square
    if(inbounds(pieceX, pieceY-2)) legalMoves[pieceX][pieceY-2] = pieceY == 6 && board[pieceX][pieceY-1] == piece.EMPTY && board[pieceX][pieceY-2] == piece.EMPTY; //two squares on first turn
    if(inbounds(pieceX-1, pieceY-1)) legalMoves[pieceX-1][pieceY-1] = isWhite(pieceX-1, pieceY-1, board); //take diagonally
    if(inbounds(pieceX+1, pieceY-1)) legalMoves[pieceX+1][pieceY-1] = isWhite(pieceX+1, pieceY-1, board);
    if(inbounds(pieceX-1, pieceY-1) && pawnMoved == pieceX-1 && pieceY == 3) legalMoves[pieceX-1][pieceY-1] = true;//en passent
    if(inbounds(pieceX+1, pieceY-1) && pawnMoved == pieceX+1 && pieceY == 3) legalMoves[pieceX+1][pieceY-1] = true;
    break;
    
    case WHITE_KNIGHT:
    case BLACK_KNIGHT:
    for(int[] d : knightDirections){ //check all 8 knight moves
      int movingX = pieceX+d[0];
      int movingY = pieceY+d[1];
      if(inbounds(movingX, movingY)) legalMoves[movingX][movingY] = enemyOrEmpty(pieceX, pieceY, movingX, movingY, board);
    }
    break;
    
    case WHITE_BISHOP:
    case BLACK_BISHOP:
    for(int[] d : bishopDirections){ //check diagonals
      count = 1;
      while(inbounds(pieceX+d[0]*count, pieceY+d[1]*count) && enemyOrEmpty(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)){
        legalMoves[pieceX+d[0]*count][pieceY+d[1]*count] = true;
        if(isEnemy(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)) break;
        count++;
      }
    }
    break;
    
    case WHITE_ROOK:
    case BLACK_ROOK:
    for(int[] d : rookDirections){ //check straight lines
      count = 1;
      while(inbounds(pieceX+d[0]*count, pieceY+d[1]*count) && enemyOrEmpty(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)){
        legalMoves[pieceX+d[0]*count][pieceY+d[1]*count] = true;
        if(isEnemy(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)) break;
        count++;
      }
    }
    break;
    
    case WHITE_QUEEN:
    case BLACK_QUEEN:
    for(int[] d : bishopDirections){ //check diagonals then straight lines
      count = 1;
      while(inbounds(pieceX+d[0]*count, pieceY+d[1]*count) && enemyOrEmpty(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)){
        legalMoves[pieceX+d[0]*count][pieceY+d[1]*count] = true;
        if(isEnemy(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)) break;
        count++;
      }
    }
    for(int[] d : rookDirections){
      count = 1;
      while(inbounds(pieceX+d[0]*count, pieceY+d[1]*count) && enemyOrEmpty(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)){
        legalMoves[pieceX+d[0]*count][pieceY+d[1]*count] = true;
        if(isEnemy(pieceX, pieceY, pieceX+d[0]*count, pieceY+d[1]*count, board)) break;
        count++;
      }
    }
    break;
    
    case WHITE_KING:
    case BLACK_KING:
    for(int[] d : bishopDirections){ //check diagonals then straight lines but only 1 square
      if(inbounds(pieceX+d[0], pieceY+d[1])) legalMoves[pieceX+d[0]][pieceY+d[1]] = enemyOrEmpty(pieceX, pieceY, pieceX+d[0], pieceY+d[1], board);
    }
    for(int[] d : rookDirections){
      if(inbounds(pieceX+d[0], pieceY+d[1])) legalMoves[pieceX+d[0]][pieceY+d[1]] = enemyOrEmpty(pieceX, pieceY, pieceX+d[0], pieceY+d[1], board);
    }
    
    if(isWhite(pieceX, pieceY, board) && !whiteInCheck(board)){ //castling
      if(whiteCanCastle[0] && whiteCanCastle[1] && board[1][0] == piece.EMPTY && board[2][0] == piece.EMPTY && board[3][0] == piece.EMPTY){ //castle queenside
        board[4][0] = piece.EMPTY;
        board[3][0] = piece.WHITE_KING;
        if(!whiteInCheck(board)) legalMoves[2][0] = true; //cant castle over check
        board[4][0] = piece.WHITE_KING;
        board[3][0] = piece.EMPTY;
      }
      if(whiteCanCastle[2] && whiteCanCastle[1] && board[5][0] == piece.EMPTY && board[6][0] == piece.EMPTY){ //castle kingside
        board[4][0] = piece.EMPTY;
        board[5][0] = piece.WHITE_KING;
        if(!whiteInCheck(board)) legalMoves[6][0] = true;
        board[4][0] = piece.WHITE_KING;
        board[5][0] = piece.EMPTY;
      }
    }
    else if(!blackInCheck(board)){
      if(blackCanCastle[0] && blackCanCastle[1] && board[1][7] == piece.EMPTY && board[2][7] == piece.EMPTY && board[3][7] == piece.EMPTY){ //castle queenside
        board[4][7] = piece.EMPTY;
        board[3][7] = piece.BLACK_KING;
        if(!blackInCheck(board)) legalMoves[2][7] = true; //cant castle over check
        board[4][7] = piece.BLACK_KING;
        board[3][7] = piece.EMPTY;
      }
      if(blackCanCastle[2] && blackCanCastle[1] && board[5][7] == piece.EMPTY && board[6][7] == piece.EMPTY){ //castle kingside
        board[4][7] = piece.EMPTY;
        board[5][7] = piece.BLACK_KING;
        if(!blackInCheck(board)) legalMoves[6][7] = true;
        board[4][7] = piece.BLACK_KING;
        board[5][7] = piece.EMPTY;
      }
    }
    break;
    
    default:
  }
  
  for(int i = 0 ; i < BOARD_WIDTH; i++){ //remove illegal moves (ones which leave the king in check)
    for(int j = 0 ; j < BOARD_HEIGHT; j++){
      if(legalMoves[i][j]){
        piece temp = board[i][j];
        board[i][j] = board[pieceX][pieceY];
        board[pieceX][pieceY] = piece.EMPTY;
        if((isWhite(i, j, board) && whiteInCheck(board)) || (isBlack(i, j, board) && blackInCheck(board))) legalMoves[i][j] = false;
        board[pieceX][pieceY] = board[i][j];
        board[i][j] = temp;
      }
    }
  }
}

//Returns true if the white king is in check on the given board
boolean whiteInCheck(piece[][] board){
  int count;
  
  int kingX = -1, kingY = -1;
  for(int i = 0 ; i < BOARD_WIDTH; i++){
    for(int j = 0 ; j < BOARD_HEIGHT; j++){
      if(board[i][j] == piece.WHITE_KING){
        kingX = i;
        kingY = j;
        break;
      }
    }
  }
  
  if(inbounds(kingX-1, kingY+1) && board[kingX-1][kingY+1] == piece.BLACK_PAWN) return true;
  if(inbounds(kingX+1, kingY+1) && board[kingX+1][kingY+1] == piece.BLACK_PAWN) return true;
  
  for(int[] d : knightDirections){
    int movingX = kingX+d[0];
    int movingY = kingY+d[1];
    if(inbounds(movingX, movingY) && board[movingX][movingY] == piece.BLACK_KNIGHT) return true; 
  }
  
  for(int[] d : bishopDirections){
    count = 1;
    while(inbounds(kingX+d[0]*count, kingY+d[1]*count) && blackOrEmpty(kingX+d[0]*count, kingY+d[1]*count, board)){
      if(board[kingX+d[0]*count][kingY+d[1]*count] == piece.BLACK_BISHOP || board[kingX+d[0]*count][kingY+d[1]*count] == piece.BLACK_QUEEN) return true;
      if(board[kingX+d[0]*count][kingY+d[1]*count] != piece.EMPTY) break;
      count++;
    }
  }
  
  for(int[] d : rookDirections){
    count = 1;
    while(inbounds(kingX+d[0]*count, kingY+d[1]*count) && blackOrEmpty(kingX+d[0]*count, kingY+d[1]*count, board)){
      if(board[kingX+d[0]*count][kingY+d[1]*count] == piece.BLACK_ROOK || board[kingX+d[0]*count][kingY+d[1]*count] == piece.BLACK_QUEEN) return true;
      if(board[kingX+d[0]*count][kingY+d[1]*count] != piece.EMPTY) break;
      count++;
    }
  }
  
  for(int[] d : rookDirections){
    if(inbounds(kingX+d[0], kingY+d[1]) && board[kingX+d[0]][kingY+d[1]] == piece.BLACK_KING) return true;
  }
  for(int[] d : bishopDirections){
    if(inbounds(kingX+d[0], kingY+d[1]) && board[kingX+d[0]][kingY+d[1]] == piece.BLACK_KING) return true;
  }
  return false;
}

//Returns true if the black king is in check on the given board
boolean blackInCheck(piece[][] board){
  int count;
  
  
  int kingX = -1, kingY = -1;
  for(int i = 0 ; i < BOARD_WIDTH; i++){
    for(int j = 0 ; j < BOARD_HEIGHT; j++){
      if(board[i][j] == piece.BLACK_KING){
        kingX = i;
        kingY = j;
        break;
      }
    }
  }
  
  if(inbounds(kingX-1, kingY-1) && board[kingX-1][kingY-1] == piece.WHITE_PAWN) return true;
  if(inbounds(kingX+1, kingY-1) && board[kingX+1][kingY-1] == piece.WHITE_PAWN) return true;
  
  for(int[] d : knightDirections){
    int movingX = kingX+d[0];
    int movingY = kingY+d[1];
    if(inbounds(movingX, movingY) && board[movingX][movingY] == piece.WHITE_KNIGHT) return true; 
  }
  
  for(int[] d : bishopDirections){
    count = 1;
    while(inbounds(kingX+d[0]*count, kingY+d[1]*count) && whiteOrEmpty(kingX+d[0]*count, kingY+d[1]*count, board)){
      if(board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_BISHOP || board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_QUEEN) return true;
      if(board[kingX+d[0]*count][kingY+d[1]*count] != piece.EMPTY) break;
      count++;
    }
  }
  
  for(int[] d : rookDirections){
    count = 1;
    while(inbounds(kingX+d[0]*count, kingY+d[1]*count) && whiteOrEmpty(kingX+d[0]*count, kingY+d[1]*count, board)){
      if(board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_ROOK || board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_QUEEN) return true;
      if(board[kingX+d[0]*count][kingY+d[1]*count] != piece.EMPTY) break;
      count++;
    }
  }
  
  for(int[] d : bishopDirections){
    count = 1;
    while(inbounds(kingX+d[0]*count, kingY+d[1]*count) && whiteOrEmpty(kingX+d[0]*count, kingY+d[1]*count, board)){
      if(board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_BISHOP || board[kingX+d[0]*count][kingY+d[1]*count] == piece.WHITE_QUEEN) return true;
      if(board[kingX+d[0]*count][kingY+d[1]*count] != piece.EMPTY) break;
      count++;
    }
  }
  
  for(int[] d : rookDirections){
    if(inbounds(kingX+d[0], kingY+d[1]) && board[kingX+d[0]][kingY+d[1]] == piece.WHITE_KING) return true;
  }
  for(int[] d : bishopDirections){
    if(inbounds(kingX+d[0], kingY+d[1]) && board[kingX+d[0]][kingY+d[1]] == piece.WHITE_KING) return true;
  }
  return false;
}

//Returns true if white has no more legal moves on the given board
boolean whiteNoLegalMoves(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
  boolean[][] legalMoves = new boolean[BOARD_WIDTH][BOARD_HEIGHT];
  for(int i = 0; i < BOARD_WIDTH; i++){
    for(int j = 0; j < BOARD_HEIGHT; j++){
      if(isWhite(i, j, board)) {
        findLegalMoves(i, j, board, legalMoves, whiteCanCastle, blackCanCastle, pawnMoved);
        for(int x = 0; x < BOARD_WIDTH; x++){
          for(int y = 0; y < BOARD_HEIGHT; y++){
            if(legalMoves[x][y]) return false;
          }
        }
      }
    }
  }
  return true;
}

//Returns true if black has no more legal moves on the given board
boolean blackNoLegalMoves(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
  boolean[][] legalMoves = new boolean[BOARD_WIDTH][BOARD_HEIGHT];
  for(int i = 0; i < BOARD_WIDTH; i++){
    for(int j = 0; j < BOARD_HEIGHT; j++){
      if(isBlack(i, j, board)){
        findLegalMoves(i, j, board, legalMoves, whiteCanCastle, blackCanCastle, pawnMoved);
        for(int x = 0; x < BOARD_WIDTH; x++){
          for(int y = 0; y < BOARD_HEIGHT; y++){
            if(legalMoves[x][y]) return false;
          }
        }
      }
    }
  }
  return true;
}

//Returns true if white is in checkmate on the given board
boolean whiteInCheckmate(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
  return whiteInCheck(board) && whiteNoLegalMoves(board, whiteCanCastle, blackCanCastle, pawnMoved);
}

//Returns true if black is in checkmate on the given board
boolean blackInCheckmate(piece[][] board, boolean[] whiteCanCastle, boolean[] blackCanCastle, int pawnMoved){
  return blackInCheck(board) && blackNoLegalMoves(board, whiteCanCastle, blackCanCastle, pawnMoved);
}
