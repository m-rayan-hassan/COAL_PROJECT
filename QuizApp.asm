; ============================================================
;  ADVANCED QUIZ APPLICATION USING MASM AND IRVINE32
; ============================================================
;  Course  : Computer Organization and Assembly Language (COAL)
;  Tool    : MASM + Irvine32 Library
;  Type    : 32-bit Console Application
;
;  FEATURES:
;    - 3 Categories (CS, Math, General Knowledge)
;    - 3 Difficulty Levels (Easy, Medium, Hard)
;    - 30 Multiple Choice Questions (10 per category)
;    - Random question order (no repeats)
;    - Score tracking, grading, and performance messages
;    - Colored text output
;    - Modular design with 17+ procedures
;
;  CONCEPTS DEMONSTRATED:
;    Procedures, Arrays, Loops, Conditional Jumps,
;    Random Number Generation, String Handling,
;    User Input/Output, Modular Programming
; ============================================================

; ==================== SETUP ====================
.386                                ; Use 386 instruction set
.model flat, stdcall                ; Flat memory model
.stack 4096                         ; 4 KB stack

INCLUDE Irvine32.inc                ; Irvine32 library

; ==================== CONSTANTS ====================
MAX_NAME     = 32                   ; Max characters for user name
NUM_PER_CAT  = 10                   ; Questions per category
PTS_CORRECT  = 10                   ; Points for a correct answer

; Color constants (foreground on black background)
CLR_WHITE    = 15
CLR_YELLOW   = 14
CLR_GREEN    = 10
CLR_RED      = 12
CLR_CYAN     = 11
CLR_MAGENTA  = 13

; ============================================================
;                      DATA SECTION
; ============================================================
.data

; ==================== USER DATA ====================
userName      BYTE  MAX_NAME DUP(0)   ; Buffer for player name
score         DWORD 0                 ; Current score
correctCount  DWORD 0                 ; Number of correct answers
wrongCount    DWORD 0                 ; Number of wrong answers
currentQNum   DWORD 0                 ; Current question number (1-based)
numQuestions  DWORD 0                 ; Total questions in this quiz
categoryBase  DWORD 0                 ; Start index of selected category
catChoice     DWORD 0                 ; Category choice (1, 2, or 3)
diffChoice    DWORD 0                 ; Difficulty choice (1, 2, or 3)
percentage    DWORD 0                 ; Calculated percentage
maxScore      DWORD 0                 ; Maximum possible score
currentQIdx   DWORD 0                 ; Absolute index of current question
userAnswer    BYTE  0                 ; User's answer (A/B/C/D)
lastCorrect   BYTE  0                 ; 1 = last answer correct, 0 = wrong

; ==================== TRACKING ARRAY ====================
; Tracks which questions have been used (0 = available, 1 = used)
usedQuestions BYTE  NUM_PER_CAT DUP(0)

; ==================== UI STRINGS ====================
separator     BYTE  "================================================", 0
promptName    BYTE  "  Enter your name: ", 0
choicePrompt  BYTE  "  Enter your choice: ", 0
ansPrompt     BYTE  "  Your Answer (A/B/C/D): ", 0
invalidMsg    BYTE  "  Invalid choice! Try again.", 0
invalidAns    BYTE  "  Invalid! Please enter A, B, C, or D.", 0
correctTxt    BYTE  "  Correct! +10 Points!", 0
wrongTxt      BYTE  "  Wrong! The correct answer was: ", 0
pressKey      BYTE  "  Press any key to continue...", 0
percentSign   BYTE  "%", 0
slashTxt      BYTE  " / ", 0

; ==================== WELCOME SCREEN ====================
welc1         BYTE  "================================================", 0
welc2         BYTE  "                                                ", 0
welc3         BYTE  "          Q U I Z   A P P L I C A T I O N      ", 0
welc4         BYTE  "                  Version 1.0                   ", 0
welc5         BYTE  "================================================", 0

; ==================== MAIN MENU STRINGS ====================
menuTitle     BYTE  "               MAIN MENU", 0
menuOpt1      BYTE  "  1. Start Quiz", 0
menuOpt2      BYTE  "  2. Instructions", 0
menuOpt3      BYTE  "  3. About Project", 0
menuOpt4      BYTE  "  4. Exit", 0

; ==================== CATEGORY MENU STRINGS ====================
catTitle      BYTE  "            SELECT CATEGORY", 0
catOpt1       BYTE  "  1. Computer Science", 0
catOpt2       BYTE  "  2. Mathematics", 0
catOpt3       BYTE  "  3. General Knowledge", 0

; ==================== DIFFICULTY MENU STRINGS ====================
diffTitle     BYTE  "           SELECT DIFFICULTY", 0
diffOpt1      BYTE  "  1. Easy     (5 Questions)", 0
diffOpt2      BYTE  "  2. Medium   (8 Questions)", 0
diffOpt3      BYTE  "  3. Hard     (10 Questions)", 0

; ==================== QUIZ PROGRESS STRINGS ====================
qNumMsg       BYTE  "  Question ", 0
ofMsg         BYTE  " of ", 0
scoreMsg      BYTE  "  Current Score: ", 0

; ==================== RESULT SCREEN STRINGS ====================
resTitle      BYTE  "            QUIZ COMPLETED!", 0
resNameLbl    BYTE  "  Player Name     : ", 0
resCatLbl     BYTE  "  Category        : ", 0
resDiffLbl    BYTE  "  Difficulty      : ", 0
resCorrectLbl BYTE  "  Correct Answers : ", 0
resWrongLbl   BYTE  "  Wrong Answers   : ", 0
resScoreLbl   BYTE  "  Final Score     : ", 0
resPercLbl    BYTE  "  Percentage      : ", 0
resGradeLbl   BYTE  "  Grade           : ", 0
resPerfLbl    BYTE  "  Performance     : ", 0

; ==================== REPLAY MENU STRINGS ====================
repTitle      BYTE  "            WHAT NEXT?", 0
repOpt1       BYTE  "  1. Play Again", 0
repOpt2       BYTE  "  2. Main Menu", 0
repOpt3       BYTE  "  3. Exit", 0

; ==================== INSTRUCTIONS TEXT ====================
inst1         BYTE  "            HOW TO PLAY", 0
inst2         BYTE  "  1. Select a category from the menu.", 0
inst3         BYTE  "  2. Select a difficulty level.", 0
inst4         BYTE  "     - Easy:   5 questions", 0
inst5         BYTE  "     - Medium: 8 questions", 0
inst6         BYTE  "     - Hard:   10 questions", 0
inst7         BYTE  "  3. Answer each multiple choice question", 0
inst8         BYTE  "     by pressing A, B, C, or D.", 0
inst9         BYTE  "  4. Each correct answer earns 10 points.", 0
inst10        BYTE  "  5. Your score and grade are shown at the end.", 0

; ==================== ABOUT TEXT ====================
abt1          BYTE  "           ABOUT THIS PROJECT", 0
abt2          BYTE  "  Project  : Advanced Quiz Application", 0
abt3          BYTE  "  Course   : Computer Organization and", 0
abt4          BYTE  "             Assembly Language (COAL)", 0
abt5          BYTE  "  Tool     : MASM + Irvine32 Library", 0
abt6          BYTE  "  Platform : 32-bit Windows Console", 0

; ==================== EXIT MESSAGE ====================
exitMsg1      BYTE  "  Thank you for playing the Quiz!", 0
exitMsg2      BYTE  "  Goodbye!", 0

; ==================== CATEGORY NAME STRINGS ====================
catName1      BYTE  "Computer Science", 0
catName2      BYTE  "Mathematics", 0
catName3      BYTE  "General Knowledge", 0

; Array of pointers to category names (for result screen)
catNames      DWORD OFFSET catName1, OFFSET catName2, OFFSET catName3

; ==================== DIFFICULTY NAME STRINGS ====================
diffName1     BYTE  "Easy", 0
diffName2     BYTE  "Medium", 0
diffName3     BYTE  "Hard", 0

; Array of pointers to difficulty names (for result screen)
diffNames     DWORD OFFSET diffName1, OFFSET diffName2, OFFSET diffName3

; ==================== GRADE STRINGS ====================
gradeAP       BYTE  "A+", 0
gradeA        BYTE  "A", 0
gradeB        BYTE  "B", 0
gradeC        BYTE  "C", 0
gradeD        BYTE  "D", 0
gradeF        BYTE  "F", 0
gradePtr      DWORD 0                 ; Pointer to current grade string

; ==================== PERFORMANCE MESSAGE STRINGS ====================
perfOutstand  BYTE  "Outstanding! You are a genius!", 0
perfExcell    BYTE  "Excellent work! Keep it up!", 0
perfGood      BYTE  "Good job! Room for improvement.", 0
perfAverage   BYTE  "Average. Study harder next time!", 0
perfNeedImp   BYTE  "Needs Improvement. Don't give up!", 0
perfPtr       DWORD 0                 ; Pointer to current performance message

; ============================================================
;          COMPUTER SCIENCE QUESTIONS (Index 0-9)
; ============================================================

; --- CS Question 1 ---
csQ1    BYTE  "What does CPU stand for?", 0
csQ1A   BYTE  "  A. Central Program Unit", 0
csQ1B   BYTE  "  B. Central Processing Unit", 0
csQ1C   BYTE  "  C. Computer Program Unit", 0
csQ1D   BYTE  "  D. Control Processing Unit", 0

; --- CS Question 2 ---
csQ2    BYTE  "What does RAM stand for?", 0
csQ2A   BYTE  "  A. Random Access Memory", 0
csQ2B   BYTE  "  B. Read Access Memory", 0
csQ2C   BYTE  "  C. Run Access Memory", 0
csQ2D   BYTE  "  D. Random Available Memory", 0

; --- CS Question 3 ---
csQ3    BYTE  "Which of the following is NOT an operating system?", 0
csQ3A   BYTE  "  A. Windows", 0
csQ3B   BYTE  "  B. Linux", 0
csQ3C   BYTE  "  C. macOS", 0
csQ3D   BYTE  "  D. Oracle", 0

; --- CS Question 4 ---
csQ4    BYTE  "What is the binary representation of decimal 10?", 0
csQ4A   BYTE  "  A. 1000", 0
csQ4B   BYTE  "  B. 1100", 0
csQ4C   BYTE  "  C. 1010", 0
csQ4D   BYTE  "  D. 1001", 0

; --- CS Question 5 ---
csQ5    BYTE  "What does HTML stand for?", 0
csQ5A   BYTE  "  A. Hyper Text Making Language", 0
csQ5B   BYTE  "  B. Hyper Text Markup Language", 0
csQ5C   BYTE  "  C. High Tech Modern Language", 0
csQ5D   BYTE  "  D. Home Tool Markup Language", 0

; --- CS Question 6 ---
csQ6    BYTE  "What is the smallest unit of data in a computer?", 0
csQ6A   BYTE  "  A. Bit", 0
csQ6B   BYTE  "  B. Byte", 0
csQ6C   BYTE  "  C. Kilobyte", 0
csQ6D   BYTE  "  D. Nibble", 0

; --- CS Question 7 ---
csQ7    BYTE  "Which of the following is an input device?", 0
csQ7A   BYTE  "  A. Monitor", 0
csQ7B   BYTE  "  B. Printer", 0
csQ7C   BYTE  "  C. Keyboard", 0
csQ7D   BYTE  "  D. Speaker", 0

; --- CS Question 8 ---
csQ8    BYTE  "What does URL stand for?", 0
csQ8A   BYTE  "  A. Uniform Resource Locator", 0
csQ8B   BYTE  "  B. Universal Resource Link", 0
csQ8C   BYTE  "  C. Uniform Reference Locator", 0
csQ8D   BYTE  "  D. Universal Resource Locator", 0

; --- CS Question 9 ---
csQ9    BYTE  "How many bits are in one byte?", 0
csQ9A   BYTE  "  A. 4", 0
csQ9B   BYTE  "  B. 8", 0
csQ9C   BYTE  "  C. 16", 0
csQ9D   BYTE  "  D. 32", 0

; --- CS Question 10 ---
csQ10   BYTE  "What does SQL stand for?", 0
csQ10A  BYTE  "  A. Simple Query Language", 0
csQ10B  BYTE  "  B. Sequential Query Language", 0
csQ10C  BYTE  "  C. Standard Query Language", 0
csQ10D  BYTE  "  D. Structured Query Language", 0

; ============================================================
;            MATHEMATICS QUESTIONS (Index 10-19)
; ============================================================

; --- Math Question 1 ---
mQ1     BYTE  "What is 15 multiplied by 13?", 0
mQ1A    BYTE  "  A. 185", 0
mQ1B    BYTE  "  B. 195", 0
mQ1C    BYTE  "  C. 205", 0
mQ1D    BYTE  "  D. 175", 0

; --- Math Question 2 ---
mQ2     BYTE  "What is the square root of 144?", 0
mQ2A    BYTE  "  A. 10", 0
mQ2B    BYTE  "  B. 14", 0
mQ2C    BYTE  "  C. 12", 0
mQ2D    BYTE  "  D. 16", 0

; --- Math Question 3 ---
mQ3     BYTE  "What is the approximate value of Pi?", 0
mQ3A    BYTE  "  A. 3.14159", 0
mQ3B    BYTE  "  B. 3.15927", 0
mQ3C    BYTE  "  C. 2.71828", 0
mQ3D    BYTE  "  D. 1.61803", 0

; --- Math Question 4 ---
mQ4     BYTE  "What is 2 raised to the power of 10?", 0
mQ4A    BYTE  "  A. 512", 0
mQ4B    BYTE  "  B. 256", 0
mQ4C    BYTE  "  C. 2048", 0
mQ4D    BYTE  "  D. 1024", 0

; --- Math Question 5 ---
mQ5     BYTE  "What is 20 percent of 250?", 0
mQ5A    BYTE  "  A. 40", 0
mQ5B    BYTE  "  B. 50", 0
mQ5C    BYTE  "  C. 60", 0
mQ5D    BYTE  "  D. 45", 0

; --- Math Question 6 ---
mQ6     BYTE  "What is the sum of all angles in a triangle?", 0
mQ6A    BYTE  "  A. 180 degrees", 0
mQ6B    BYTE  "  B. 360 degrees", 0
mQ6C    BYTE  "  C. 90 degrees", 0
mQ6D    BYTE  "  D. 270 degrees", 0

; --- Math Question 7 ---
mQ7     BYTE  "What is the factorial of 5 (5!)?", 0
mQ7A    BYTE  "  A. 60", 0
mQ7B    BYTE  "  B. 24", 0
mQ7C    BYTE  "  C. 120", 0
mQ7D    BYTE  "  D. 720", 0

; --- Math Question 8 ---
mQ8     BYTE  "What is the next prime number after 7?", 0
mQ8A    BYTE  "  A. 9", 0
mQ8B    BYTE  "  B. 11", 0
mQ8C    BYTE  "  C. 13", 0
mQ8D    BYTE  "  D. 8", 0

; --- Math Question 9 ---
mQ9     BYTE  "What is the formula for the area of a circle?", 0
mQ9A    BYTE  "  A. Pi * r * r", 0
mQ9B    BYTE  "  B. 2 * Pi * r", 0
mQ9C    BYTE  "  C. Pi * d", 0
mQ9D    BYTE  "  D. r * r", 0

; --- Math Question 10 ---
mQ10    BYTE  "What is the value of 0! (zero factorial)?", 0
mQ10A   BYTE  "  A. 0", 0
mQ10B   BYTE  "  B. Undefined", 0
mQ10C   BYTE  "  C. -1", 0
mQ10D   BYTE  "  D. 1", 0

; ============================================================
;         GENERAL KNOWLEDGE QUESTIONS (Index 20-29)
; ============================================================

; --- GK Question 1 ---
gkQ1    BYTE  "What is the capital city of France?", 0
gkQ1A   BYTE  "  A. Paris", 0
gkQ1B   BYTE  "  B. London", 0
gkQ1C   BYTE  "  C. Berlin", 0
gkQ1D   BYTE  "  D. Madrid", 0

; --- GK Question 2 ---
gkQ2    BYTE  "Which is the largest planet in our solar system?", 0
gkQ2A   BYTE  "  A. Saturn", 0
gkQ2B   BYTE  "  B. Mars", 0
gkQ2C   BYTE  "  C. Jupiter", 0
gkQ2D   BYTE  "  D. Neptune", 0

; --- GK Question 3 ---
gkQ3    BYTE  "Who wrote the play Romeo and Juliet?", 0
gkQ3A   BYTE  "  A. Charles Dickens", 0
gkQ3B   BYTE  "  B. William Shakespeare", 0
gkQ3C   BYTE  "  C. Jane Austen", 0
gkQ3D   BYTE  "  D. Mark Twain", 0

; --- GK Question 4 ---
gkQ4    BYTE  "Which is the largest ocean on Earth?", 0
gkQ4A   BYTE  "  A. Atlantic Ocean", 0
gkQ4B   BYTE  "  B. Indian Ocean", 0
gkQ4C   BYTE  "  C. Arctic Ocean", 0
gkQ4D   BYTE  "  D. Pacific Ocean", 0

; --- GK Question 5 ---
gkQ5    BYTE  "What is the chemical symbol for Gold?", 0
gkQ5A   BYTE  "  A. Go", 0
gkQ5B   BYTE  "  B. Au", 0
gkQ5C   BYTE  "  C. Ag", 0
gkQ5D   BYTE  "  D. Gd", 0

; --- GK Question 6 ---
gkQ6    BYTE  "How many continents are there on Earth?", 0
gkQ6A   BYTE  "  A. 7", 0
gkQ6B   BYTE  "  B. 5", 0
gkQ6C   BYTE  "  C. 6", 0
gkQ6D   BYTE  "  D. 8", 0

; --- GK Question 7 ---
gkQ7    BYTE  "What is the approximate speed of light?", 0
gkQ7A   BYTE  "  A. 150,000 km/s", 0
gkQ7B   BYTE  "  B. 200,000 km/s", 0
gkQ7C   BYTE  "  C. 300,000 km/s", 0
gkQ7D   BYTE  "  D. 400,000 km/s", 0

; --- GK Question 8 ---
gkQ8    BYTE  "Which is the longest river in the world?", 0
gkQ8A   BYTE  "  A. Nile", 0
gkQ8B   BYTE  "  B. Amazon", 0
gkQ8C   BYTE  "  C. Mississippi", 0
gkQ8D   BYTE  "  D. Yangtze", 0

; --- GK Question 9 ---
gkQ9    BYTE  "Who was the first person to walk on the Moon?", 0
gkQ9A   BYTE  "  A. Buzz Aldrin", 0
gkQ9B   BYTE  "  B. Neil Armstrong", 0
gkQ9C   BYTE  "  C. Yuri Gagarin", 0
gkQ9D   BYTE  "  D. John Glenn", 0

; --- GK Question 10 ---
gkQ10   BYTE  "What is the chemical formula for water?", 0
gkQ10A  BYTE  "  A. CO2", 0
gkQ10B  BYTE  "  B. NaCl", 0
gkQ10C  BYTE  "  C. O2", 0
gkQ10D  BYTE  "  D. H2O", 0

; ============================================================
;              POINTER ARRAYS (for array-based access)
; ============================================================
; Each array holds 30 DWORD pointers (10 per category).
; Index  0- 9 = Computer Science
; Index 10-19 = Mathematics
; Index 20-29 = General Knowledge
; ============================================================

; --- Array of pointers to question strings ---
allQ  DWORD OFFSET csQ1,  OFFSET csQ2,  OFFSET csQ3,  OFFSET csQ4,  OFFSET csQ5
      DWORD OFFSET csQ6,  OFFSET csQ7,  OFFSET csQ8,  OFFSET csQ9,  OFFSET csQ10
      DWORD OFFSET mQ1,   OFFSET mQ2,   OFFSET mQ3,   OFFSET mQ4,   OFFSET mQ5
      DWORD OFFSET mQ6,   OFFSET mQ7,   OFFSET mQ8,   OFFSET mQ9,   OFFSET mQ10
      DWORD OFFSET gkQ1,  OFFSET gkQ2,  OFFSET gkQ3,  OFFSET gkQ4,  OFFSET gkQ5
      DWORD OFFSET gkQ6,  OFFSET gkQ7,  OFFSET gkQ8,  OFFSET gkQ9,  OFFSET gkQ10

; --- Array of pointers to Option A strings ---
allA  DWORD OFFSET csQ1A, OFFSET csQ2A, OFFSET csQ3A, OFFSET csQ4A, OFFSET csQ5A
      DWORD OFFSET csQ6A, OFFSET csQ7A, OFFSET csQ8A, OFFSET csQ9A, OFFSET csQ10A
      DWORD OFFSET mQ1A,  OFFSET mQ2A,  OFFSET mQ3A,  OFFSET mQ4A,  OFFSET mQ5A
      DWORD OFFSET mQ6A,  OFFSET mQ7A,  OFFSET mQ8A,  OFFSET mQ9A,  OFFSET mQ10A
      DWORD OFFSET gkQ1A, OFFSET gkQ2A, OFFSET gkQ3A, OFFSET gkQ4A, OFFSET gkQ5A
      DWORD OFFSET gkQ6A, OFFSET gkQ7A, OFFSET gkQ8A, OFFSET gkQ9A, OFFSET gkQ10A

; --- Array of pointers to Option B strings ---
allB  DWORD OFFSET csQ1B, OFFSET csQ2B, OFFSET csQ3B, OFFSET csQ4B, OFFSET csQ5B
      DWORD OFFSET csQ6B, OFFSET csQ7B, OFFSET csQ8B, OFFSET csQ9B, OFFSET csQ10B
      DWORD OFFSET mQ1B,  OFFSET mQ2B,  OFFSET mQ3B,  OFFSET mQ4B,  OFFSET mQ5B
      DWORD OFFSET mQ6B,  OFFSET mQ7B,  OFFSET mQ8B,  OFFSET mQ9B,  OFFSET mQ10B
      DWORD OFFSET gkQ1B, OFFSET gkQ2B, OFFSET gkQ3B, OFFSET gkQ4B, OFFSET gkQ5B
      DWORD OFFSET gkQ6B, OFFSET gkQ7B, OFFSET gkQ8B, OFFSET gkQ9B, OFFSET gkQ10B

; --- Array of pointers to Option C strings ---
allC  DWORD OFFSET csQ1C, OFFSET csQ2C, OFFSET csQ3C, OFFSET csQ4C, OFFSET csQ5C
      DWORD OFFSET csQ6C, OFFSET csQ7C, OFFSET csQ8C, OFFSET csQ9C, OFFSET csQ10C
      DWORD OFFSET mQ1C,  OFFSET mQ2C,  OFFSET mQ3C,  OFFSET mQ4C,  OFFSET mQ5C
      DWORD OFFSET mQ6C,  OFFSET mQ7C,  OFFSET mQ8C,  OFFSET mQ9C,  OFFSET mQ10C
      DWORD OFFSET gkQ1C, OFFSET gkQ2C, OFFSET gkQ3C, OFFSET gkQ4C, OFFSET gkQ5C
      DWORD OFFSET gkQ6C, OFFSET gkQ7C, OFFSET gkQ8C, OFFSET gkQ9C, OFFSET gkQ10C

; --- Array of pointers to Option D strings ---
allD  DWORD OFFSET csQ1D, OFFSET csQ2D, OFFSET csQ3D, OFFSET csQ4D, OFFSET csQ5D
      DWORD OFFSET csQ6D, OFFSET csQ7D, OFFSET csQ8D, OFFSET csQ9D, OFFSET csQ10D
      DWORD OFFSET mQ1D,  OFFSET mQ2D,  OFFSET mQ3D,  OFFSET mQ4D,  OFFSET mQ5D
      DWORD OFFSET mQ6D,  OFFSET mQ7D,  OFFSET mQ8D,  OFFSET mQ9D,  OFFSET mQ10D
      DWORD OFFSET gkQ1D, OFFSET gkQ2D, OFFSET gkQ3D, OFFSET gkQ4D, OFFSET gkQ5D
      DWORD OFFSET gkQ6D, OFFSET gkQ7D, OFFSET gkQ8D, OFFSET gkQ9D, OFFSET gkQ10D

; ============================================================
;                   CORRECT ANSWERS ARRAY
; ============================================================
; Stores the correct answer letter for each of the 30 questions.
; Index  0- 9 = CS answers
; Index 10-19 = Math answers
; Index 20-29 = GK answers
; ============================================================
answers BYTE 'B','A','D','C','B','A','C','A','B','D'     ; CS
        BYTE 'B','C','A','D','B','A','C','B','A','D'     ; Math
        BYTE 'A','C','B','D','B','A','C','A','B','D'     ; GK

; ============================================================
;                      CODE SECTION
; ============================================================
.code

; ============================================================
;  main - Entry point of the program
;  Purpose: Initializes RNG, gets user name, runs main loop
; ============================================================
main PROC

    call Randomize              ; Seed the random number generator
    call ClearScreen            ; Clear the console
    call GetUserName            ; Ask for and store player name

mainMenuLoop:
    call MainMenu               ; Display menu, returns choice in EAX

    cmp  eax, 1                 ; Option 1: Start Quiz
    je   doStartQuiz
    cmp  eax, 2                 ; Option 2: Instructions
    je   doInstructions
    cmp  eax, 3                 ; Option 3: About
    je   doAbout
    cmp  eax, 4                 ; Option 4: Exit
    je   doExit
    jmp  mainMenuLoop           ; Invalid (shouldn't happen), loop back

doStartQuiz:
    call SelectCategory         ; Let user pick a category
    call SelectDifficulty       ; Let user pick difficulty level
    call StartQuiz              ; Run the quiz
    call ShowResult             ; Display results and grade
    call ReplayMenu             ; Ask what to do next (returns in EAX)

    cmp  eax, 1                 ; 1 = Play Again
    je   doStartQuiz
    cmp  eax, 3                 ; 3 = Exit
    je   doExit
    jmp  mainMenuLoop           ; 2 = Main Menu (default)

doInstructions:
    call ShowInstructions       ; Display instructions screen
    jmp  mainMenuLoop           ; Return to main menu

doAbout:
    call ShowAbout              ; Display about screen
    jmp  mainMenuLoop           ; Return to main menu

doExit:
    call ExitProgram            ; Display goodbye and exit

main ENDP

; ============================================================
;  ClearScreen - Clears the console screen
;  Purpose: Wrapper around Irvine32's Clrscr
; ============================================================
ClearScreen PROC
    call Clrscr
    ret
ClearScreen ENDP

; ============================================================
;  GetUserName - Asks for and stores the player's name
;  Purpose: Displays welcome screen and reads name input
;  Output:  userName buffer is filled with the player's name
; ============================================================
GetUserName PROC

    ; --- Display Welcome Banner ---
    mov  eax, CLR_YELLOW
    call SetTextColor

    mov  edx, OFFSET welc1         ; Top border
    call WriteString
    call Crlf
    mov  edx, OFFSET welc2         ; Blank line
    call WriteString
    call Crlf
    mov  edx, OFFSET welc3         ; Title text
    call WriteString
    call Crlf
    mov  edx, OFFSET welc4         ; Version
    call WriteString
    call Crlf
    mov  edx, OFFSET welc5         ; Bottom border
    call WriteString
    call Crlf
    call Crlf

    ; --- Prompt for Name ---
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET promptName    ; "Enter your name: "
    call WriteString

    ; Read the name string into userName buffer
    mov  edx, OFFSET userName
    mov  ecx, MAX_NAME             ; Max characters to read
    call ReadString                ; Reads until Enter is pressed

    call Crlf
    ret

GetUserName ENDP

; ============================================================
;  MainMenu - Displays the main menu and gets user choice
;  Purpose: Shows 4 options and validates input
;  Output:  EAX = user choice (1, 2, 3, or 4)
; ============================================================
MainMenu PROC

    call ClearScreen

    ; --- Display Menu Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET menuTitle     ; "MAIN MENU"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- Display Menu Options ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET menuOpt1     ; "1. Start Quiz"
    call WriteString
    call Crlf
    mov  edx, OFFSET menuOpt2     ; "2. Instructions"
    call WriteString
    call Crlf
    mov  edx, OFFSET menuOpt3     ; "3. About Project"
    call WriteString
    call Crlf
    mov  edx, OFFSET menuOpt4     ; "4. Exit"
    call WriteString
    call Crlf
    call Crlf

    ; --- Get and Validate Input ---
menuInput:
    mov  edx, OFFSET choicePrompt  ; "Enter your choice: "
    call WriteString
    call ReadChar                  ; Read single character into AL
    call WriteChar                 ; Echo the character
    call Crlf

    ; Validate: must be '1', '2', '3', or '4'
    cmp  al, '1'
    jb   menuInvalid
    cmp  al, '4'
    ja   menuInvalid

    ; Convert ASCII to number and return in EAX
    sub  al, '0'                   ; '1'->1, '2'->2, etc.
    movzx eax, al                  ; Zero-extend to 32 bits
    ret

menuInvalid:
    ; Show error message in red
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidMsg
    call WriteString
    call Crlf
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  menuInput                 ; Ask again

MainMenu ENDP

; ============================================================
;  SelectCategory - Lets the user choose a quiz category
;  Purpose: Sets categoryBase (0, 10, or 20) and catChoice
;  Output:  catChoice = 1/2/3, categoryBase = 0/10/20
; ============================================================
SelectCategory PROC

    call ClearScreen

    ; --- Display Category Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET catTitle      ; "SELECT CATEGORY"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- Display Options ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET catOpt1      ; "1. Computer Science"
    call WriteString
    call Crlf
    mov  edx, OFFSET catOpt2      ; "2. Mathematics"
    call WriteString
    call Crlf
    mov  edx, OFFSET catOpt3      ; "3. General Knowledge"
    call WriteString
    call Crlf
    call Crlf

    ; --- Get and Validate Input ---
catInput:
    mov  edx, OFFSET choicePrompt
    call WriteString
    call ReadChar
    call WriteChar
    call Crlf

    cmp  al, '1'
    je   catCS
    cmp  al, '2'
    je   catMath
    cmp  al, '3'
    je   catGK

    ; Invalid input
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidMsg
    call WriteString
    call Crlf
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  catInput

catCS:
    mov  catChoice, 1
    mov  categoryBase, 0           ; CS starts at index 0
    ret

catMath:
    mov  catChoice, 2
    mov  categoryBase, 10          ; Math starts at index 10
    ret

catGK:
    mov  catChoice, 3
    mov  categoryBase, 20          ; GK starts at index 20
    ret

SelectCategory ENDP

; ============================================================
;  SelectDifficulty - Lets the user choose a difficulty level
;  Purpose: Sets numQuestions (5, 8, or 10) and diffChoice
;  Output:  diffChoice = 1/2/3, numQuestions = 5/8/10
; ============================================================
SelectDifficulty PROC

    call ClearScreen

    ; --- Display Difficulty Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET diffTitle     ; "SELECT DIFFICULTY"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- Display Options ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET diffOpt1     ; "1. Easy (5 Questions)"
    call WriteString
    call Crlf
    mov  edx, OFFSET diffOpt2     ; "2. Medium (8 Questions)"
    call WriteString
    call Crlf
    mov  edx, OFFSET diffOpt3     ; "3. Hard (10 Questions)"
    call WriteString
    call Crlf
    call Crlf

    ; --- Get and Validate Input ---
diffInput:
    mov  edx, OFFSET choicePrompt
    call WriteString
    call ReadChar
    call WriteChar
    call Crlf

    cmp  al, '1'
    je   diffEasy
    cmp  al, '2'
    je   diffMedium
    cmp  al, '3'
    je   diffHard

    ; Invalid input
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidMsg
    call WriteString
    call Crlf
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  diffInput

diffEasy:
    mov  diffChoice, 1
    mov  numQuestions, 5           ; Easy = 5 questions
    ret

diffMedium:
    mov  diffChoice, 2
    mov  numQuestions, 8           ; Medium = 8 questions
    ret

diffHard:
    mov  diffChoice, 3
    mov  numQuestions, 10          ; Hard = 10 questions
    ret

SelectDifficulty ENDP

; ============================================================
;  StartQuiz - Runs the quiz loop
;  Purpose: Initializes score, loops through questions,
;           calls helper procedures for each question
; ============================================================
StartQuiz PROC

    ; --- Initialize Quiz Variables ---
    mov  score, 0
    mov  correctCount, 0
    mov  wrongCount, 0
    mov  currentQNum, 0

    ; --- Clear the usedQuestions tracking array ---
    ; Set all 10 bytes to 0 (available)
    mov  ecx, NUM_PER_CAT          ; Loop 10 times
    lea  esi, usedQuestions        ; Point to the array
    xor  al, al                    ; AL = 0
clearLoop:
    mov  [esi], al                 ; Set element to 0
    inc  esi                       ; Move to next byte
    loop clearLoop                 ; Repeat until ECX = 0

    ; --- Calculate Maximum Score ---
    mov  eax, numQuestions
    imul eax, PTS_CORRECT          ; maxScore = numQuestions * 10
    mov  maxScore, eax

    ; --- Quiz Loop ---
    ; We use a manual counter because ECX is modified by procedures
    mov  ecx, numQuestions         ; Set loop counter

quizLoop:
    push ecx                      ; Save loop counter on stack

    inc  currentQNum               ; Increment question number

    call ClearScreen               ; Clear screen for new question
    call RandomQuestionGenerator   ; Get random question (result in EAX)
    mov  currentQIdx, eax          ; Store the question index

    call DisplayQuestion           ; Show the question and options
    call GetAnswer                 ; Get user's answer (A/B/C/D)
    call CheckAnswer               ; Check if answer is correct
    call UpdateScore               ; Update score and counters

    ; --- Pause before next question ---
    call Crlf
    mov  edx, OFFSET pressKey      ; "Press any key to continue..."
    call WriteString
    call ReadChar                  ; Wait for keypress

    pop  ecx                       ; Restore loop counter
    dec  ecx                       ; Decrement manually
    cmp  ecx, 0                    ; Check if done
    jg   quizLoop                  ; If counter > 0, continue

    ret

StartQuiz ENDP

; ============================================================
;  RandomQuestionGenerator - Picks a random unused question
;  Purpose: Generates a random index within the category
;           that hasn't been used yet in this quiz session
;  Output:  EAX = absolute question index (0-29)
;  Uses:    usedQuestions array, categoryBase variable
; ============================================================
RandomQuestionGenerator PROC

    push ebx                       ; Save EBX

tryAgain:
    ; Generate random number from 0 to 9
    mov  eax, NUM_PER_CAT          ; EAX = 10 (range)
    call RandomRange               ; EAX = random number 0-9

    ; Check if this question index is already used
    lea  ebx, usedQuestions        ; EBX = address of tracking array
    cmp  BYTE PTR [ebx + eax], 1  ; Is it used?
    je   tryAgain                  ; If yes, generate another random

    ; Mark this question as used
    mov  BYTE PTR [ebx + eax], 1

    ; Calculate absolute index: categoryBase + random offset
    add  eax, categoryBase         ; EAX = absolute question index

    pop  ebx                       ; Restore EBX
    ret

RandomQuestionGenerator ENDP

; ============================================================
;  DisplayQuestion - Shows the current question with options
;  Purpose: Displays question number, score, question text,
;           and all four answer options
;  Input:   currentQIdx, currentQNum, numQuestions, score
; ============================================================
DisplayQuestion PROC

    ; --- Display Quiz Progress ---
    mov  eax, CLR_CYAN
    call SetTextColor

    mov  edx, OFFSET qNumMsg      ; "Question "
    call WriteString
    mov  eax, currentQNum          ; Display current question number
    call WriteDec
    mov  edx, OFFSET ofMsg         ; " of "
    call WriteString
    mov  eax, numQuestions         ; Display total questions
    call WriteDec
    call Crlf

    ; --- Display Current Score ---
    mov  edx, OFFSET scoreMsg     ; "Current Score: "
    call WriteString
    mov  eax, score
    call WriteDec
    call Crlf
    call Crlf

    ; --- Display Separator ---
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf

    ; --- Display Question Text (in yellow) ---
    mov  eax, CLR_YELLOW
    call SetTextColor

    ; Access question string from pointer array:
    ; allQ[currentQIdx * 4] gives us the pointer to the string
    mov  esi, OFFSET allQ          ; ESI = base of question pointer array
    mov  eax, currentQIdx          ; EAX = question index
    mov  edx, [esi + eax * 4]     ; EDX = pointer to question string
    call WriteString
    call Crlf
    call Crlf

    ; --- Display Options (in white) ---
    mov  eax, CLR_WHITE
    call SetTextColor

    ; Option A
    mov  esi, OFFSET allA
    mov  eax, currentQIdx
    mov  edx, [esi + eax * 4]
    call WriteString
    call Crlf

    ; Option B
    mov  esi, OFFSET allB
    mov  eax, currentQIdx
    mov  edx, [esi + eax * 4]
    call WriteString
    call Crlf

    ; Option C
    mov  esi, OFFSET allC
    mov  eax, currentQIdx
    mov  edx, [esi + eax * 4]
    call WriteString
    call Crlf

    ; Option D
    mov  esi, OFFSET allD
    mov  eax, currentQIdx
    mov  edx, [esi + eax * 4]
    call WriteString
    call Crlf

    ; --- Separator ---
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ret

DisplayQuestion ENDP

; ============================================================
;  GetAnswer - Reads the user's answer (A, B, C, or D)
;  Purpose: Prompts user, reads a character, converts to
;           uppercase, and validates it
;  Output:  userAnswer = validated uppercase letter (A-D)
; ============================================================
GetAnswer PROC

getAnsLoop:
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET ansPrompt     ; "Your Answer (A/B/C/D): "
    call WriteString

    call ReadChar                  ; Read character into AL

    ; Save character before echoing (in case WriteChar modifies AL)
    push eax
    call WriteChar                 ; Echo the character
    call Crlf
    pop  eax                       ; Restore character

    ; --- Convert lowercase to uppercase ---
    cmp  al, 'a'                   ; Is it below 'a'?
    jb   noConvert                 ; If yes, skip conversion
    cmp  al, 'z'                   ; Is it above 'z'?
    ja   noConvert                 ; If yes, skip conversion
    sub  al, 32                    ; Convert: 'a'->A, 'b'->B, etc.

noConvert:
    ; --- Validate: must be A, B, C, or D ---
    cmp  al, 'A'
    je   validAnswer
    cmp  al, 'B'
    je   validAnswer
    cmp  al, 'C'
    je   validAnswer
    cmp  al, 'D'
    je   validAnswer

    ; Invalid character entered
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidAns    ; "Invalid! Enter A, B, C, or D."
    call WriteString
    call Crlf
    jmp  getAnsLoop                ; Ask again

validAnswer:
    mov  userAnswer, al            ; Store the valid answer
    ret

GetAnswer ENDP

; ============================================================
;  CheckAnswer - Compares user answer with correct answer
;  Purpose: Looks up the correct answer from the answers array
;           and compares it with the user's answer
;  Input:   currentQIdx, userAnswer
;  Output:  lastCorrect = 1 if correct, 0 if wrong
;           Displays feedback message to user
; ============================================================
CheckAnswer PROC

    ; --- Get the correct answer from the answers array ---
    mov  esi, OFFSET answers       ; ESI = base of answers array
    mov  eax, currentQIdx          ; EAX = question index
    mov  bl, [esi + eax]           ; BL = correct answer character

    ; --- Compare with user's answer ---
    mov  al, userAnswer            ; AL = user's answer
    cmp  al, bl                    ; Compare user answer with correct
    je   answerCorrect             ; Jump if they match

    ; --- Wrong Answer ---
    mov  lastCorrect, 0            ; Set flag to wrong
    call Crlf
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET wrongTxt      ; "Wrong! The correct answer was: "
    call WriteString
    mov  al, bl                    ; AL = correct answer character
    call WriteChar                 ; Display the correct letter
    call Crlf
    jmp  checkDone

answerCorrect:
    ; --- Correct Answer ---
    mov  lastCorrect, 1            ; Set flag to correct
    call Crlf
    mov  eax, CLR_GREEN
    call SetTextColor
    mov  edx, OFFSET correctTxt    ; "Correct! +10 Points!"
    call WriteString
    call Crlf

checkDone:
    ; Reset text color to white
    mov  eax, CLR_WHITE
    call SetTextColor
    ret

CheckAnswer ENDP

; ============================================================
;  UpdateScore - Updates the score based on the last answer
;  Purpose: If last answer was correct, adds points and
;           increments correct count. Otherwise increments
;           wrong count.
;  Input:   lastCorrect flag
;  Output:  score, correctCount, wrongCount are updated
; ============================================================
UpdateScore PROC

    cmp  lastCorrect, 1            ; Was the last answer correct?
    jne  wasWrong                  ; If not, jump to wrong handler

    ; --- Correct: Add points ---
    add  score, PTS_CORRECT        ; score += 10
    inc  correctCount              ; correctCount++
    ret

wasWrong:
    ; --- Wrong: No points added ---
    inc  wrongCount                ; wrongCount++
    ret

UpdateScore ENDP

; ============================================================
;  CalculateGrade - Calculates percentage and determines grade
;  Purpose: Uses score and maxScore to compute percentage,
;           then assigns a letter grade and performance message
;  Input:   score, maxScore
;  Output:  percentage, gradePtr, perfPtr
; ============================================================
CalculateGrade PROC

    ; --- Calculate Percentage ---
    ; Formula: percentage = (score * 100) / maxScore
    xor  edx, edx                  ; Clear EDX for multiplication
    mov  eax, score                ; EAX = score
    mov  ebx, 100
    mul  ebx                       ; EDX:EAX = score * 100
    mov  ebx, maxScore
    div  ebx                       ; EAX = percentage (integer)
    mov  percentage, eax           ; Store the result

    ; --- Determine Grade Based on Percentage ---
    ; 90-100 = A+, 80-89 = A, 70-79 = B, 60-69 = C, 50-59 = D, <50 = F

    cmp  eax, 90
    jge  isAPlus
    cmp  eax, 80
    jge  isA
    cmp  eax, 70
    jge  isB
    cmp  eax, 60
    jge  isC
    cmp  eax, 50
    jge  isD

    ; --- Grade F (Below 50) ---
    mov  gradePtr, OFFSET gradeF
    mov  perfPtr, OFFSET perfNeedImp
    ret

isAPlus:
    mov  gradePtr, OFFSET gradeAP
    mov  perfPtr, OFFSET perfOutstand
    ret

isA:
    mov  gradePtr, OFFSET gradeA
    mov  perfPtr, OFFSET perfExcell
    ret

isB:
    mov  gradePtr, OFFSET gradeB
    mov  perfPtr, OFFSET perfGood
    ret

isC:
    mov  gradePtr, OFFSET gradeC
    mov  perfPtr, OFFSET perfAverage
    ret

isD:
    mov  gradePtr, OFFSET gradeD
    mov  perfPtr, OFFSET perfNeedImp
    ret

CalculateGrade ENDP

; ============================================================
;  ShowResult - Displays the complete result screen
;  Purpose: Shows player name, category, difficulty, scores,
;           percentage, grade, and performance message
;  Input:   All quiz result variables
; ============================================================
ShowResult PROC

    call CalculateGrade            ; Calculate percentage and grade
    call ClearScreen

    ; ============ HEADER ============
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET resTitle      ; "QUIZ COMPLETED!"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; ============ PLAYER INFO ============
    mov  eax, CLR_CYAN
    call SetTextColor

    ; Player Name
    mov  edx, OFFSET resNameLbl    ; "Player Name     : "
    call WriteString
    mov  edx, OFFSET userName
    call WriteString
    call Crlf

    ; Category (use pointer array to get name)
    mov  edx, OFFSET resCatLbl     ; "Category        : "
    call WriteString
    mov  esi, OFFSET catNames      ; Array of category name pointers
    mov  eax, catChoice
    dec  eax                       ; Convert 1-based to 0-based
    mov  edx, [esi + eax * 4]     ; Get pointer to category name
    call WriteString
    call Crlf

    ; Difficulty (use pointer array to get name)
    mov  edx, OFFSET resDiffLbl   ; "Difficulty      : "
    call WriteString
    mov  esi, OFFSET diffNames    ; Array of difficulty name pointers
    mov  eax, diffChoice
    dec  eax
    mov  edx, [esi + eax * 4]
    call WriteString
    call Crlf
    call Crlf

    ; ============ SEPARATOR ============
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf

    ; ============ SCORES ============
    ; Correct Answers (green)
    mov  eax, CLR_GREEN
    call SetTextColor
    mov  edx, OFFSET resCorrectLbl ; "Correct Answers : "
    call WriteString
    mov  eax, correctCount
    call WriteDec
    call Crlf

    ; Wrong Answers (red)
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET resWrongLbl   ; "Wrong Answers   : "
    call WriteString
    mov  eax, wrongCount
    call WriteDec
    call Crlf
    call Crlf

    ; Final Score (yellow)
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET resScoreLbl   ; "Final Score     : "
    call WriteString
    mov  eax, score
    call WriteDec
    mov  edx, OFFSET slashTxt      ; " / "
    call WriteString
    mov  eax, maxScore
    call WriteDec
    call Crlf

    ; Percentage
    mov  edx, OFFSET resPercLbl    ; "Percentage      : "
    call WriteString
    mov  eax, percentage
    call WriteDec
    mov  edx, OFFSET percentSign   ; "%"
    call WriteString
    call Crlf

    ; Grade
    mov  edx, OFFSET resGradeLbl   ; "Grade           : "
    call WriteString
    mov  edx, gradePtr             ; Pointer to grade string
    call WriteString
    call Crlf
    call Crlf

    ; ============ SEPARATOR ============
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf

    ; ============ PERFORMANCE MESSAGE ============
    mov  eax, CLR_MAGENTA
    call SetTextColor
    mov  edx, OFFSET resPerfLbl    ; "Performance     : "
    call WriteString
    mov  edx, perfPtr              ; Pointer to performance message
    call WriteString
    call Crlf
    call Crlf

    ; Reset color
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ret

ShowResult ENDP

; ============================================================
;  ShowInstructions - Displays the instructions screen
;  Purpose: Shows how to play the quiz
; ============================================================
ShowInstructions PROC

    call ClearScreen

    ; --- Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET inst1         ; "HOW TO PLAY"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- Instructions Text ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET inst2         ; Step 1
    call WriteString
    call Crlf
    mov  edx, OFFSET inst3         ; Step 2
    call WriteString
    call Crlf
    mov  edx, OFFSET inst4         ; Easy details
    call WriteString
    call Crlf
    mov  edx, OFFSET inst5         ; Medium details
    call WriteString
    call Crlf
    mov  edx, OFFSET inst6         ; Hard details
    call WriteString
    call Crlf
    mov  edx, OFFSET inst7         ; Step 3
    call WriteString
    call Crlf
    mov  edx, OFFSET inst8         ; Answer format
    call WriteString
    call Crlf
    mov  edx, OFFSET inst9         ; Step 4
    call WriteString
    call Crlf
    mov  edx, OFFSET inst10        ; Step 5
    call WriteString
    call Crlf
    call Crlf

    ; --- Wait for key press ---
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET pressKey
    call WriteString
    call ReadChar                  ; Wait for any key

    ret

ShowInstructions ENDP

; ============================================================
;  ShowAbout - Displays information about the project
;  Purpose: Shows project name, course, and technology used
; ============================================================
ShowAbout PROC

    call ClearScreen

    ; --- Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET abt1          ; "ABOUT THIS PROJECT"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- About Text ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET abt2          ; Project name
    call WriteString
    call Crlf
    mov  edx, OFFSET abt3          ; Course line 1
    call WriteString
    call Crlf
    mov  edx, OFFSET abt4          ; Course line 2
    call WriteString
    call Crlf
    mov  edx, OFFSET abt5          ; Technology
    call WriteString
    call Crlf
    mov  edx, OFFSET abt6          ; Platform
    call WriteString
    call Crlf
    call Crlf

    ; --- Wait for key press ---
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET pressKey
    call WriteString
    call ReadChar

    ret

ShowAbout ENDP

; ============================================================
;  ReplayMenu - Asks what the user wants to do next
;  Purpose: Shows Play Again, Main Menu, Exit options
;  Output:  EAX = user choice (1 = again, 2 = menu, 3 = exit)
; ============================================================
ReplayMenu PROC

    ; --- Display Replay Header ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    mov  edx, OFFSET repTitle      ; "WHAT NEXT?"
    call WriteString
    call Crlf
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; --- Display Options ---
    mov  eax, CLR_WHITE
    call SetTextColor

    mov  edx, OFFSET repOpt1      ; "1. Play Again"
    call WriteString
    call Crlf
    mov  edx, OFFSET repOpt2      ; "2. Main Menu"
    call WriteString
    call Crlf
    mov  edx, OFFSET repOpt3      ; "3. Exit"
    call WriteString
    call Crlf
    call Crlf

    ; --- Get and Validate Input ---
repInput:
    mov  edx, OFFSET choicePrompt
    call WriteString
    call ReadChar
    call WriteChar
    call Crlf

    cmp  al, '1'
    jb   repInvalid
    cmp  al, '3'
    ja   repInvalid

    ; Convert to number and return
    sub  al, '0'
    movzx eax, al
    ret

repInvalid:
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidMsg
    call WriteString
    call Crlf
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  repInput

ReplayMenu ENDP

; ============================================================
;  ExitProgram - Displays goodbye message and exits
;  Purpose: Clean exit from the application
; ============================================================
ExitProgram PROC

    call ClearScreen

    ; --- Display Goodbye ---
    mov  eax, CLR_YELLOW
    call SetTextColor
    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    mov  edx, OFFSET exitMsg1     ; "Thank you for playing!"
    call WriteString
    call Crlf
    mov  edx, OFFSET exitMsg2     ; "Goodbye!"
    call WriteString
    call Crlf
    call Crlf

    mov  edx, OFFSET separator
    call WriteString
    call Crlf
    call Crlf

    ; Reset color to white before exit
    mov  eax, CLR_WHITE
    call SetTextColor

    ; Wait for final key press
    mov  edx, OFFSET pressKey
    call WriteString
    call ReadChar

    exit                           ; Irvine32 macro: calls ExitProcess

ExitProgram ENDP

; ============================================================
;  END OF PROGRAM
; ============================================================
END main
