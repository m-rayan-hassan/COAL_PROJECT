# Quiz Application — Complete Architecture & Code Walkthrough

> **Course:** Computer Organization and Assembly Language (COAL)  
> **Technology:** MASM + Irvine32 Library  
> **Platform:** 32-bit Windows Console Application  
> **Source File:** [QuizApp.asm](QuizApp.asm)

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Setup Directives](#2-setup-directives)
3. [Constants](#3-constants)
4. [Data Section — Memory Layout](#4-data-section--memory-layout)
5. [Complete Program Workflow](#5-complete-program-workflow)
6. [Procedure-by-Procedure Walkthrough](#6-procedure-by-procedure-walkthrough)
7. [Key Concepts Summary](#7-key-concepts-summary)
8. [Data Flow Diagram](#8-data-flow-diagram)
9. [How to Build and Run](#9-how-to-build-and-run)

---

## 1. High-Level Architecture

The program is built on three pillars:

```text
+---------------------------------------------+
|              SETUP (Lines 1-30)             |
|                                             |
|  .386 / .model / .stack                     |
|  INCLUDE Irvine32.inc                       |
|  Constants (colors, sizes)                  |
+---------------------------------------------+
                       |
                       v
+---------------------------------------------+
|           DATA SECTION (Lines 35-370)       |
|                                             |
|  User Variables                             |
|  UI Strings                                 |
|  30 Questions + Options                     |
|  Pointer Arrays (allQ, allA-D)              |
|  Answers Array                              |
+---------------------------------------------+
                       |
                       v
+---------------------------------------------+
|           CODE SECTION (Lines 375-1565)     |
|                                             |
|  main PROC — Game Loop                      |
|  17 Procedures                              |
+---------------------------------------------+
```

| Section | Lines | Purpose |
|---|---|---|
| Setup directives | 1–30 | Processor, memory model, stack, library |
| Constants | 31–40 | Named values (colors, sizes, points) |
| `.data` section | 42–370 | All variables, strings, questions, arrays |
| `.code` section | 375–1565 | `main` + 17 procedures |

### Program Structure Overview

```
QuizApp.asm
│
├── SETUP
│   ├── .386                    (32-bit instruction set)
│   ├── .model flat, stdcall    (memory model)
│   ├── .stack 4096             (stack size)
│   └── INCLUDE Irvine32.inc    (library)
│
├── .data SECTION
│   ├── User Variables          (score, name, counters)
│   ├── UI Strings              (menus, prompts, labels)
│   ├── Question Strings        (30 questions × 5 strings each)
│   ├── Pointer Arrays          (allQ, allA, allB, allC, allD)
│   ├── Answers Array           (30 correct answer characters)
│   ├── Name/Grade Arrays       (category names, grade strings)
│   └── Tracking Array          (usedQuestions - prevents repeats)
│
└── .code SECTION
    ├── main                    (entry point & game loop)
    ├── ClearScreen             (screen clearing wrapper)
    ├── GetUserName             (welcome screen & name input)
    ├── MainMenu                (4-option main menu)
    ├── SelectCategory          (category selection)
    ├── SelectDifficulty        (difficulty selection)
    ├── StartQuiz               (quiz loop controller)
    ├── RandomQuestionGenerator (random unused question picker)
    ├── DisplayQuestion         (question & options display)
    ├── GetAnswer               (input reading & validation)
    ├── CheckAnswer             (answer comparison & feedback)
    ├── UpdateScore             (score & counter updates)
    ├── CalculateGrade          (percentage & grade computation)
    ├── ShowResult              (full result screen)
    ├── ShowInstructions        (how-to-play screen)
    ├── ShowAbout               (project info screen)
    ├── ReplayMenu              (post-quiz options)
    └── ExitProgram             (goodbye & exit)
```

---

## 2. Setup Directives

**Lines 27-30 of QuizApp.asm:**

```asm
.386                    ; Use 386 instruction set (enables 32-bit registers)
.model flat, stdcall    ; Flat memory model (single 4GB address space)
.stack 4096             ; Reserve 4KB for the stack
INCLUDE Irvine32.inc    ; Pull in Irvine32 function prototypes
```

### What Each Directive Does

| Directive | Meaning |
|---|---|
| `.386` | Tells the assembler we want 32-bit registers (EAX, EBX, ECX, EDX, ESI, EDI, etc.) |
| `.model flat, stdcall` | **Flat** = no segment juggling (single address space). **stdcall** = Windows calling convention (callee cleans the stack) |
| `.stack 4096` | The stack is where `CALL`/`RET` return addresses and `PUSH`/`POP` values are stored. 4KB is sufficient for this program |
| `INCLUDE Irvine32.inc` | Imports declarations for library functions like `WriteString`, `ReadChar`, `Clrscr`, `RandomRange`, etc. |

---

## 3. Constants

**Lines 33-40:**

```asm
MAX_NAME     = 32       ; Max length for player name
NUM_PER_CAT  = 10       ; Each category has exactly 10 questions
PTS_CORRECT  = 10       ; Points awarded per correct answer

CLR_WHITE    = 15       ; Color code: white text on black background
CLR_YELLOW   = 14       ; Color code: yellow text
CLR_GREEN    = 10       ; Color code: green text (correct answers)
CLR_RED      = 12       ; Color code: red text (wrong answers)
CLR_CYAN     = 11       ; Color code: cyan text (progress display)
CLR_MAGENTA  = 13       ; Color code: magenta text (performance)
```

> [!NOTE]
> **How colors work:** Colors are computed as `(background × 16) + foreground`. Since the background is always black (0), the constant equals just the foreground value. For example, yellow on black = `0 × 16 + 14 = 14`.

### Color Values Reference

```
 0 = Black        8 = Dark Gray
 1 = Blue         9 = Light Blue
 2 = Green       10 = Light Green
 3 = Cyan        11 = Light Cyan
 4 = Red         12 = Light Red
 5 = Magenta     13 = Light Magenta
 6 = Brown       14 = Yellow
 7 = Light Gray  15 = White
```

---

## 4. Data Section — Memory Layout

### 4.1 User/Game Variables (Lines 46-62)

```asm
userName      BYTE  32 DUP(0)    ; 32-byte buffer for player name
score         DWORD 0            ; Running score (multiples of 10)
correctCount  DWORD 0            ; How many right answers
wrongCount    DWORD 0            ; How many wrong answers
currentQNum   DWORD 0            ; Which question we're on (1-based)
numQuestions  DWORD 0            ; Total questions this quiz (5, 8, or 10)
categoryBase  DWORD 0            ; Starting index in arrays (0, 10, or 20)
catChoice     DWORD 0            ; Category choice (1, 2, or 3)
diffChoice    DWORD 0            ; Difficulty choice (1, 2, or 3)
percentage    DWORD 0            ; Calculated percentage score
maxScore      DWORD 0            ; Maximum possible score
currentQIdx   DWORD 0            ; Absolute index of current question (0-29)
userAnswer    BYTE  0            ; The letter user entered (A/B/C/D)
lastCorrect   BYTE  0            ; Flag: 1 = correct, 0 = wrong
```

These are **global variables** — every procedure reads/writes them directly. This avoids parameter passing, which keeps the code simple for students.

### Variable Relationships Diagram

```text
[ Set by User ]                 [ Derived ]
  catChoice       ----------->    categoryBase
  diffChoice      ----------->    numQuestions  --->  maxScore

[ Updated Per Question ]        [ Running Totals ]
  currentQIdx     ----------->    userAnswer    --->  lastCorrect
                                       |
                                       +----------->  score
                                       |
                                       +----------->  correctCount
                                       |
                                       +----------->  wrongCount

[ Final Results ]
  score           ----------->    percentage    --->  gradePtr & perfPtr
```

### 4.2 Tracking Array — Preventing Repeat Questions (Line 65)

```asm
usedQuestions BYTE 10 DUP(0)    ; 10 bytes, one per question in category
```

This is the **repeat-prevention** mechanism. Each byte corresponds to one question in the selected category:

```
Index:  [0] [1] [2] [3] [4] [5] [6] [7] [8] [9]
Value:   0   0   0   0   0   0   0   0   0   0    ← All available at start

After picking question 3 and 7:
Value:   0   0   0   1   0   0   0   1   0   0    ← 3 and 7 are marked used

RandomQuestionGenerator checks this array:
  - Generates random number (e.g., 3)
  - Checks usedQuestions[3] → it's 1 (used!)
  - Generates another random number (e.g., 5)
  - Checks usedQuestions[5] → it's 0 (available!)
  - Marks usedQuestions[5] = 1
  - Returns index 5 + categoryBase
```

### 4.3 Question Data Structure (Lines 102-310)

Each question is a group of **5 null-terminated strings**:

```asm
csQ1    BYTE  "What does CPU stand for?", 0     ; Question text
csQ1A   BYTE  "  A. Central Program Unit", 0    ; Option A
csQ1B   BYTE  "  B. Central Processing Unit", 0 ; Option B
csQ1C   BYTE  "  C. Computer Program Unit", 0   ; Option C
csQ1D   BYTE  "  D. Control Processing Unit", 0 ; Option D
```

Each string ends with `, 0` (null terminator) — this is how `WriteString` knows where the string ends.

**Memory layout example:**
```
Address    Label     Content                              Size
────────   ─────     ────────────────────────────────     ────
0x404000   csQ1      "What does CPU stand for?\0"         25 bytes
0x404019   csQ1A     "  A. Central Program Unit\0"        27 bytes
0x404034   csQ1B     "  B. Central Processing Unit\0"     30 bytes
0x404052   csQ1C     "  C. Computer Program Unit\0"       28 bytes
0x40406E   csQ1D     "  D. Control Processing Unit\0"     30 bytes
0x40408C   csQ2      "What does RAM stand for?\0"         25 bytes
...
```

> [!NOTE]
> Strings are stored **sequentially** in memory, but their sizes vary. We **cannot** use simple arithmetic to find question #5 because each string is a different length. This is why we need **pointer arrays**.

### 4.4 Pointer Arrays — The Key Data Structure (Lines 315-360)

Instead of fixed-size strings (wasteful), we use **arrays of pointers**. Each element is a **4-byte DWORD** containing the memory address of a string.

```asm
; Array of 30 DWORD pointers to question strings
allQ  DWORD OFFSET csQ1,  OFFSET csQ2,  ..., OFFSET gkQ10

; Arrays of 30 DWORD pointers to option strings
allA  DWORD OFFSET csQ1A, OFFSET csQ2A, ..., OFFSET gkQ10A
allB  DWORD OFFSET csQ1B, OFFSET csQ2B, ..., OFFSET gkQ10B
allC  DWORD OFFSET csQ1C, OFFSET csQ2C, ..., OFFSET gkQ10C
allD  DWORD OFFSET csQ1D, OFFSET csQ2D, ..., OFFSET gkQ10D
```

### How Pointer Array Indexing Works

```
allQ (array of 30 DWORDs, each 4 bytes):

Byte Offset:  0         4         8        ...  36        40       ...  116
Index:        0         1         2        ...  9         10       ...  29
Value:      [addr]    [addr]    [addr]        [addr]    [addr]        [addr]
              ↓         ↓         ↓              ↓        ↓              ↓
            csQ1      csQ2      csQ3           csQ10     mQ1           gkQ10
            "CPU?"    "RAM?"    "NOT OS?"      "SQL?"   "15x13?"      "H2O?"

             ←─── Computer Science ───→  ←─── Mathematics ───→  ←── General Knowledge ──→
                    Index 0-9                 Index 10-19              Index 20-29
```

**To access question #i in code:**

```asm
mov  esi, OFFSET allQ      ; ESI = base address of pointer array
mov  eax, i                ; EAX = question index (0-29)
mov  edx, [esi + eax * 4]  ; EDX = pointer to the question string
                            ;   eax * 4 because each DWORD is 4 bytes
                            ;   This reads the DWORD at address (esi + eax*4)
call WriteString            ; Print the string pointed to by EDX
```

**Visual breakdown of `[esi + eax * 4]`:**

```
If esi = base address of allQ, and eax = 3:

esi + 3 * 4 = esi + 12

allQ:  [ptr0][ptr1][ptr2][ptr3][ptr4]...
bytes:  0-3   4-7   8-11  12-15  16-19
                          ^^^^
                     We read this DWORD
                     It contains the address of csQ4
```

### 4.5 Answers Array (Lines 366-370)

```asm
answers BYTE 'B','A','D','C','B','A','C','A','B','D'   ; CS  (index 0-9)
        BYTE 'B','C','A','D','B','A','C','B','A','D'   ; Math (index 10-19)
        BYTE 'A','C','B','D','B','A','C','A','B','D'   ; GK  (index 20-29)
```

This is a flat **byte array** of 30 ASCII characters. Unlike the pointer arrays (4 bytes per element), each element is just **1 byte**.

**To check the answer for question #i:**
```asm
mov  esi, OFFSET answers    ; ESI = base of answers array
mov  eax, currentQIdx       ; EAX = e.g., 4
mov  bl, [esi + eax]         ; bl = answers[4] = 'B' (no *4 needed, each is 1 byte!)
cmp  userAnswer, bl          ; Compare with what user entered
```

### All 30 Questions & Answers Reference

| Index | Category | Question | Answer |
|---|---|---|---|
| 0 | CS | What does CPU stand for? | B |
| 1 | CS | What does RAM stand for? | A |
| 2 | CS | Which is NOT an operating system? | D |
| 3 | CS | Binary of decimal 10? | C |
| 4 | CS | What does HTML stand for? | B |
| 5 | CS | Smallest unit of data? | A |
| 6 | CS | Which is an input device? | C |
| 7 | CS | What does URL stand for? | A |
| 8 | CS | Bits in one byte? | B |
| 9 | CS | What does SQL stand for? | D |
| 10 | Math | 15 × 13 = ? | B (195) |
| 11 | Math | Square root of 144? | C (12) |
| 12 | Math | Value of Pi? | A (3.14159) |
| 13 | Math | 2^10 = ? | D (1024) |
| 14 | Math | 20% of 250? | B (50) |
| 15 | Math | Sum of angles in triangle? | A (180) |
| 16 | Math | Factorial of 5? | C (120) |
| 17 | Math | Next prime after 7? | B (11) |
| 18 | Math | Area of circle formula? | A (πr²) |
| 19 | Math | Value of 0!? | D (1) |
| 20 | GK | Capital of France? | A (Paris) |
| 21 | GK | Largest planet? | C (Jupiter) |
| 22 | GK | Who wrote Romeo and Juliet? | B (Shakespeare) |
| 23 | GK | Largest ocean? | D (Pacific) |
| 24 | GK | Chemical symbol for Gold? | B (Au) |
| 25 | GK | How many continents? | A (7) |
| 26 | GK | Speed of light? | C (300,000 km/s) |
| 27 | GK | Longest river? | A (Nile) |
| 28 | GK | First person on Moon? | B (Neil Armstrong) |
| 29 | GK | Chemical formula for water? | D (H2O) |

---

## 5. Complete Program Workflow

### 5.1 Main Execution Flow

```text
[ Program Starts ]
        |
        v
[ call Randomize ]  (seed RNG with system time)
        |
        v
[ call GetUserName ] (welcome screen + read name)
        |
        v
+---> [ call MainMenu ] (display 4 options)
|       |
|       +--- (Press 1) ---> [ SelectCategory ] ---> [ SelectDifficulty ] ---> [ StartQuiz ] ---> [ ShowResult ]
|       |                                                                                             |
|       +--- (Press 2) ---> [ ShowInstructions ] ------+                                              v
|       |                                              |                                       [ ReplayMenu ]
|       +--- (Press 3) ---> [ ShowAbout ] -------------+                                              |
|       |                                              |                                              |
|       |   <------------------------------------------+                                              |
|       |                                                                                             |
|       +--- (Press 4) ---> [ ExitProgram ]                                                           |
|                               ^                                                                     |
|                               |                                                                     |
+----------- (Press 2) ---------+<--- (Press 1 = Restart from Category) ------------------------------+
                                |
                                +---- (Press 3) ------------------------------------------------------+
```

### 5.2 Quiz Loop Detail (Inside StartQuiz)

```text
[ INITIALIZE ]
  score = 0, correctCount = 0, wrongCount = 0
  Clear usedQuestions array
  Calculate maxScore
        |
        v
+-> [ LOOP START ]  <---------------------------------------+
|   More questions? (counter > 0)                           |
|       |                                                   |
|       +-- (Yes) --> push ecx (save loop counter)          |
|                       |                                   |
|                       v                                   |
|                     inc currentQNum                       |
|                     call ClearScreen                      |
|                     call RandomQuestionGenerator          |
|                     call DisplayQuestion                  |
|                     call GetAnswer                        |
|                     call CheckAnswer                      |
|                     call UpdateScore                      |
|                     Press any key to continue...          |
|                       |                                   |
|                       v                                   |
|                     pop ecx (restore loop counter)        |
|                     dec ecx                               |
|                       |                                   |
|                       +-----------------------------------+
|
+---- (No) --> [ return to main ]
```

### 5.3 Random Question Generator Workflow

```text
[ Enter RandomQuestionGenerator ]
        |
        v
+-> [ Generate random 0-9 ]
|     (call RandomRange)
|       |
|       v
|   [ Is usedQuestions[random] == 1? ]
|       |
+-------+ (Yes, already used)
        |
        | (No, available)
        v
    [ Mark as used ]
      usedQuestions[random] = 1
        |
        v
    [ Add category offset ]
      EAX = random + categoryBase
        |
        v
    [ Return EAX ]
      (absolute index 0-29)
```

**Step-by-step example** (Category = Math, `categoryBase = 10`):

```
Quiz starts. usedQuestions = [0,0,0,0,0,0,0,0,0,0]

Question 1:
  RandomRange(10) → 3
  usedQuestions[3] = 0 → Available!
  Mark: usedQuestions[3] = 1
  Return: 3 + 10 = 13 → Math Question 4 ("2^10 = ?")

Question 2:
  RandomRange(10) → 3
  usedQuestions[3] = 1 → Already used! Try again.
  RandomRange(10) → 7
  usedQuestions[7] = 0 → Available!
  Mark: usedQuestions[7] = 1
  Return: 7 + 10 = 17 → Math Question 8 ("Next prime after 7?")

Question 3:
  RandomRange(10) → 7
  usedQuestions[7] = 1 → Used! Try again.
  RandomRange(10) → 0
  usedQuestions[0] = 0 → Available!
  Mark: usedQuestions[0] = 1
  Return: 0 + 10 = 10 → Math Question 1 ("15 × 13?")

usedQuestions now = [1,0,0,1,0,0,0,1,0,0]
```

---

## 6. Procedure-by-Procedure Walkthrough

### 6.1 `main` — Entry Point & Game Loop

**Lines 380-416**

```asm
main PROC
    call Randomize          ; Seed random number generator with system time
    call ClearScreen
    call GetUserName        ; Show welcome, read name

mainMenuLoop:               ; ← This label is the "home base" of the program
    call MainMenu           ; Returns user choice in EAX
    
    cmp  eax, 1             ; Compare choice with 1
    je   doStartQuiz        ; Jump if Equal → start quiz
    cmp  eax, 2
    je   doInstructions     ; Jump if Equal → instructions
    cmp  eax, 3
    je   doAbout            ; Jump if Equal → about
    cmp  eax, 4
    je   doExit             ; Jump if Equal → exit
    jmp  mainMenuLoop       ; Safety net: loop back

doStartQuiz:
    call SelectCategory
    call SelectDifficulty
    call StartQuiz
    call ShowResult
    call ReplayMenu         ; Returns 1, 2, or 3 in EAX
    cmp  eax, 1
    je   doStartQuiz        ; Play Again → restart quiz flow
    cmp  eax, 3
    je   doExit             ; Exit
    jmp  mainMenuLoop       ; Main Menu (default)

doInstructions:
    call ShowInstructions
    jmp  mainMenuLoop       ; Return to menu after viewing

doAbout:
    call ShowAbout
    jmp  mainMenuLoop       ; Return to menu after viewing

doExit:
    call ExitProgram        ; Goodbye and terminate
main ENDP
```

> [!IMPORTANT]
> **`jmp` vs `call`:** Notice how navigation within `main` uses **`jmp` (jump)**, not `call`. This is because we don't want to push return addresses — we're just redirecting flow within the same procedure. Each `call` to a sub-procedure properly returns with `ret`, keeping the stack balanced.

### 6.2 `ClearScreen` — Screen Clearing Wrapper

```asm
ClearScreen PROC
    call Clrscr        ; Irvine32 function that clears the console
    ret
ClearScreen ENDP
```

A simple wrapper to satisfy the project requirement. Calls `Clrscr` from the Irvine32 library.

### 6.3 `GetUserName` — Welcome Screen & Name Input

**Lines 425-457**

```asm
GetUserName PROC
    ; Display yellow banner
    mov  eax, CLR_YELLOW       ; EAX = 14 (yellow)
    call SetTextColor          ; Set console text color

    mov  edx, OFFSET welc3     ; EDX = address of title string
    call WriteString           ; Print: "Q U I Z   A P P L I C A T I O N"
    call Crlf                  ; Print newline

    ; Read name
    mov  eax, CLR_WHITE
    call SetTextColor
    mov  edx, OFFSET promptName ; "Enter your name: "
    call WriteString

    mov  edx, OFFSET userName   ; EDX = address of name buffer
    mov  ecx, MAX_NAME          ; ECX = max characters to read (32)
    call ReadString             ; Reads keyboard input until Enter
    ret
GetUserName ENDP
```

**How `ReadString` works:**
| Register | Must Contain | Purpose |
|---|---|---|
| EDX | Address of buffer | Where to store the typed characters |
| ECX | Maximum length | Prevents buffer overflow |

The function reads characters until Enter is pressed, stores them in the buffer, and **null-terminates** the string. The Enter key itself is NOT stored.

### 6.4 `MainMenu` — 4-Option Menu with Input Validation

**Lines 463-510**

The key pattern — **input validation loop:**

```asm
menuInput:                          ; ← Label for retry loop
    mov  edx, OFFSET choicePrompt   ; "Enter your choice: "
    call WriteString
    call ReadChar                   ; Read ONE character into AL (no Enter needed)
    call WriteChar                  ; Echo it (ReadChar doesn't auto-echo)
    call Crlf                       ; Print newline
    
    cmp  al, '1'                    ; Compare AL with ASCII '1' (value 0x31)
    jb   menuInvalid                ; Jump if Below → invalid (al < '1')
    cmp  al, '4'                    ; Compare with ASCII '4' (value 0x34)
    ja   menuInvalid                ; Jump if Above → invalid (al > '4')
    
    ; Valid input! Convert ASCII digit to number
    sub  al, '0'                    ; '1' - '0' = 1,  '2' - '0' = 2, etc.
    movzx eax, al                   ; Zero-extend AL (8-bit) → EAX (32-bit)
    ret                             ; Return with choice in EAX

menuInvalid:
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidMsg     ; "Invalid choice! Try again."
    call WriteString
    call Crlf
    mov  eax, CLR_WHITE
    call SetTextColor
    jmp  menuInput                  ; ← Jump back and ask again
```

> [!TIP]
> **`ReadChar`** reads a **single keystroke** immediately — no Enter key needed. This makes the menu feel snappy and responsive.

> [!NOTE]
> **ASCII conversion:** Characters are stored as ASCII codes. `'0'` = 48, `'1'` = 49, ... `'9'` = 57. Subtracting `'0'` (48) converts the ASCII code to the actual number: `49 - 48 = 1`.

### 6.5 `SelectCategory` — Category Selection

**Lines 516-570**

Displays three choices and sets two key variables:

| User Presses | `catChoice` | `categoryBase` | Questions Used |
|---|---|---|---|
| `'1'` | 1 | **0** | Index 0–9 (Computer Science) |
| `'2'` | 2 | **10** | Index 10–19 (Mathematics) |
| `'3'` | 3 | **20** | Index 20–29 (General Knowledge) |

**`categoryBase`** is the magic number — it's added to every random offset in `RandomQuestionGenerator` to select questions from the right category.

```asm
catCS:
    mov  catChoice, 1
    mov  categoryBase, 0       ; CS questions start at index 0
    ret
catMath:
    mov  catChoice, 2
    mov  categoryBase, 10      ; Math questions start at index 10
    ret
catGK:
    mov  catChoice, 3
    mov  categoryBase, 20      ; GK questions start at index 20
    ret
```

### 6.6 `SelectDifficulty` — Difficulty Selection

**Lines 576-625**

Sets `numQuestions` which controls how many times the quiz loop runs:

| User Presses | `diffChoice` | `numQuestions` | Max Score |
|---|---|---|---|
| `'1'` | 1 | **5** (Easy) | 50 |
| `'2'` | 2 | **8** (Medium) | 80 |
| `'3'` | 3 | **10** (Hard) | 100 |

### 6.7 `StartQuiz` — The Quiz Loop Controller

**Lines 631-680**

This is the **heart of the program**. It orchestrates everything:

```asm
StartQuiz PROC
    ; 1. Reset all quiz state
    mov  score, 0
    mov  correctCount, 0
    mov  wrongCount, 0
    mov  currentQNum, 0

    ; 2. Clear tracking array using a LOOP
    mov  ecx, NUM_PER_CAT      ; ECX = 10 (loop counter)
    lea  esi, usedQuestions     ; ESI = address of tracking array
    xor  al, al                ; AL = 0 (xor with itself = 0)
clearLoop:
    mov  [esi], al             ; Write 0 to current byte
    inc  esi                   ; Advance pointer by 1 byte
    loop clearLoop             ; Decrement ECX, jump if ECX ≠ 0

    ; 3. Calculate maximum possible score
    mov  eax, numQuestions     ; e.g., 5
    imul eax, PTS_CORRECT      ; 5 × 10 = 50
    mov  maxScore, eax         ; maxScore = 50

    ; 4. Quiz loop (runs numQuestions times)
    mov  ecx, numQuestions
quizLoop:
    push ecx                   ; ⬆ SAVE counter on stack
    inc  currentQNum           ; Question number: 1, 2, 3...

    call ClearScreen
    call RandomQuestionGenerator  ; → EAX = random question index
    mov  currentQIdx, eax         ; Store for other procedures to use

    call DisplayQuestion       ; Show question + 4 options
    call GetAnswer             ; Read user's A/B/C/D
    call CheckAnswer           ; Compare and show feedback
    call UpdateScore           ; Update score/counters

    call Crlf
    mov  edx, OFFSET pressKey  ; "Press any key to continue..."
    call WriteString
    call ReadChar              ; Wait for keypress

    pop  ecx                   ; ⬇ RESTORE counter from stack
    dec  ecx                   ; Manually decrement
    cmp  ecx, 0               ; Is counter zero?
    jg   quizLoop              ; If greater than 0, do next question

    ret                        ; All questions done, return
StartQuiz ENDP
```

> [!IMPORTANT]
> **Why `push ecx` / `pop ecx`?** The quiz loop uses ECX as a counter. But Irvine32 functions like `RandomRange`, `ReadChar`, and `WriteString` **destroy ECX internally** as a side effect. If we didn't save ECX to the stack before calling these functions, our loop counter would be corrupted. The stack acts as safe storage:
> ```
> Stack before push: [...]
> Stack after push:  [..., ECX_value]    ← saved
> ... procedures run, ECX gets trashed ...
> Stack after pop:   [...]               ← ECX restored to original value
> ```

### 6.8 `RandomQuestionGenerator` — Random Unused Question Picker

**Lines 686-710**

```asm
RandomQuestionGenerator PROC
    push ebx                       ; Save EBX register

tryAgain:
    mov  eax, NUM_PER_CAT          ; EAX = 10
    call RandomRange               ; EAX = random number from 0 to 9

    ; Check if this question was already used
    lea  ebx, usedQuestions        ; EBX = address of tracking array
    cmp  BYTE PTR [ebx + eax], 1  ; Is usedQuestions[eax] == 1?
    je   tryAgain                  ; If yes (used), try another number

    ; Available! Mark it as used
    mov  BYTE PTR [ebx + eax], 1  ; usedQuestions[eax] = 1

    ; Convert local index (0-9) to absolute index (0-29)
    add  eax, categoryBase         ; EAX = local + categoryBase

    pop  ebx                       ; Restore EBX
    ret                            ; Return with absolute index in EAX
RandomQuestionGenerator ENDP
```

> [!NOTE]
> **`BYTE PTR`** is needed because the assembler can't determine the operand size from `[ebx + eax]` alone. We explicitly tell it we're working with bytes (not words or dwords).

### 6.9 `DisplayQuestion` — Question & Options Display

**Lines 716-773**

Displays the question progress, current score, question text, and all four options:

```
  Question 3 of 10
  Current Score: 20
================================================
What is the binary representation of decimal 10?

  A. 1000
  B. 1100
  C. 1010
  D. 1001
================================================
```

The core mechanism accesses each pointer array:

```asm
; Display the question text
mov  esi, OFFSET allQ          ; ESI = base of question pointer array
mov  eax, currentQIdx          ; EAX = 3 (for example)
mov  edx, [esi + eax * 4]     ; EDX = allQ[3] = address of csQ4 string
call WriteString               ; Prints the question

; Display Option A (same pattern, different array)
mov  esi, OFFSET allA          ; ESI = base of Option A pointer array
mov  eax, currentQIdx          ; Same index
mov  edx, [esi + eax * 4]     ; EDX = allA[3] = address of csQ4A
call WriteString               ; Prints "  A. 1000"

; Option B, C, D follow the same pattern with allB, allC, allD
```

### 6.10 `GetAnswer` — Input Reading & Validation

**Lines 779-816**

```asm
GetAnswer PROC
getAnsLoop:
    mov  edx, OFFSET ansPrompt     ; "Your Answer (A/B/C/D): "
    call WriteString
    call ReadChar                  ; AL = character typed

    push eax                       ; Save char (WriteChar might modify AL)
    call WriteChar                 ; Echo character to screen
    call Crlf                      ; Newline
    pop  eax                       ; Restore character

    ; --- Convert lowercase to uppercase ---
    cmp  al, 'a'                   ; Is it >= 'a' (97)?
    jb   noConvert                 ; If below, skip
    cmp  al, 'z'                   ; Is it <= 'z' (122)?
    ja   noConvert                 ; If above, skip
    sub  al, 32                    ; 'a'(97) - 32 = 'A'(65)
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

    ; Invalid: show error and retry
    mov  eax, CLR_RED
    call SetTextColor
    mov  edx, OFFSET invalidAns    ; "Invalid! Enter A, B, C, or D."
    call WriteString
    call Crlf
    jmp  getAnsLoop                ; Ask again

validAnswer:
    mov  userAnswer, al            ; Store validated answer
    ret
GetAnswer ENDP
```

> [!NOTE]
> **Uppercase conversion:** The ASCII table places uppercase letters (A=65 to Z=90) exactly 32 positions before lowercase letters (a=97 to z=122). So `'a' - 32 = 'A'`, `'b' - 32 = 'B'`, etc. This lets the user type either case.

### 6.11 `CheckAnswer` — Answer Comparison & Feedback

**Lines 822-862**

```asm
CheckAnswer PROC
    ; Get the correct answer from the answers byte array
    mov  esi, OFFSET answers       ; ESI = base of answers array
    mov  eax, currentQIdx          ; EAX = question index (0-29)
    mov  bl, [esi + eax]           ; BL = correct answer character
                                   ; (no *4 — each element is 1 byte)

    ; Compare with user's answer
    mov  al, userAnswer            ; AL = what user typed
    cmp  al, bl                    ; Compare the two characters
    je   answerCorrect             ; If Equal → correct!

    ; ── Wrong Answer ──
    mov  lastCorrect, 0            ; Set flag = wrong
    mov  eax, CLR_RED              ; Red text
    call SetTextColor
    mov  edx, OFFSET wrongTxt      ; "Wrong! The correct answer was: "
    call WriteString
    mov  al, bl                    ; AL = correct answer char
    call WriteChar                 ; Print it (e.g., 'B')
    call Crlf
    jmp  checkDone

answerCorrect:
    ; ── Correct Answer ──
    mov  lastCorrect, 1            ; Set flag = correct
    mov  eax, CLR_GREEN            ; Green text
    call SetTextColor
    mov  edx, OFFSET correctTxt    ; "Correct! +10 Points!"
    call WriteString
    call Crlf

checkDone:
    mov  eax, CLR_WHITE            ; Reset to white text
    call SetTextColor
    ret
CheckAnswer ENDP
```

### 6.12 `UpdateScore` — Score & Counter Updates

**Lines 868-884**

```asm
UpdateScore PROC
    cmp  lastCorrect, 1            ; Was the last answer correct?
    jne  wasWrong                  ; Jump if Not Equal (flag ≠ 1)

    ; Correct path
    add  score, PTS_CORRECT        ; score += 10
    inc  correctCount              ; correctCount++
    ret

wasWrong:
    ; Wrong path
    inc  wrongCount                ; wrongCount++
    ret                            ; (score unchanged — 0 points for wrong)
UpdateScore ENDP
```

> [!TIP]
> `CheckAnswer` and `UpdateScore` are deliberately **separate procedures** even though they could be combined. This demonstrates **modular programming** — each procedure does exactly one thing. `CheckAnswer` determines correctness and shows feedback. `UpdateScore` modifies the numeric state.

### 6.13 `CalculateGrade` — Percentage & Grade Computation

**Lines 890-933**

This procedure performs **integer arithmetic** and a **grading chain**:

```asm
CalculateGrade PROC
    ; ── Step 1: Calculate percentage ──
    ; Formula: percentage = (score × 100) ÷ maxScore
    
    xor  edx, edx          ; EDX = 0 (clear upper 32 bits)
    mov  eax, score         ; EAX = score (e.g., 70)
    mov  ebx, 100
    mul  ebx                ; EDX:EAX = 70 × 100 = 7000
                            ; MUL produces 64-bit result in EDX:EAX
    mov  ebx, maxScore      ; EBX = 100 (hard mode)
    div  ebx                ; EAX = 7000 ÷ 100 = 70 (quotient)
                            ; EDX = remainder (discarded)
    mov  percentage, eax    ; Store percentage = 70

    ; ── Step 2: Determine grade ──
    ; Uses a chain of comparisons (like if-else-if)
    
    cmp  eax, 90            ; percentage >= 90?
    jge  isAPlus            ; Yes → A+
    cmp  eax, 80            ; >= 80?
    jge  isA                ; Yes → A
    cmp  eax, 70            ; >= 70?
    jge  isB                ; Yes → B
    cmp  eax, 60            ; >= 60?
    jge  isC                ; Yes → C
    cmp  eax, 50            ; >= 50?
    jge  isD                ; Yes → D
    ; else → F (fall through)
    
    mov  gradePtr, OFFSET gradeF
    mov  perfPtr, OFFSET perfNeedImp
    ret

isAPlus:
    mov  gradePtr, OFFSET gradeAP       ; "A+"
    mov  perfPtr, OFFSET perfOutstand   ; "Outstanding! You are a genius!"
    ret
isA:
    mov  gradePtr, OFFSET gradeA        ; "A"
    mov  perfPtr, OFFSET perfExcell     ; "Excellent work! Keep it up!"
    ret
; ... similar for B, C, D
```

> [!IMPORTANT]
> **Why `xor edx, edx` before `mul`?** The `MUL` instruction computes `EDX:EAX = EAX × operand`, producing a **64-bit result** across two registers. Then `DIV` divides the **64-bit value `EDX:EAX`** by the operand. If EDX contains leftover data from a previous operation, the division will produce wrong results or even crash with a divide overflow exception. Clearing EDX first guarantees correctness.

### Grade Thresholds

| Percentage | Grade | Performance Message |
|---|---|---|
| 90–100% | A+ | "Outstanding! You are a genius!" |
| 80–89% | A | "Excellent work! Keep it up!" |
| 70–79% | B | "Good job! Room for improvement." |
| 60–69% | C | "Average. Study harder next time!" |
| 50–59% | D | "Needs Improvement. Don't give up!" |
| 0–49% | F | "Needs Improvement. Don't give up!" |

### 6.14 `ShowResult` — Full Result Screen

**Lines 939-1012**

Displays a comprehensive results screen:

```
================================================
            QUIZ COMPLETED!
================================================

  Player Name     : John
  Category        : Computer Science
  Difficulty      : Hard

================================================
  Correct Answers : 8
  Wrong Answers   : 2

  Final Score     : 80 / 100
  Percentage      : 80%
  Grade           : A

================================================
  Performance     : Excellent work! Keep it up!

================================================
```

**Key technique — looking up names from pointer arrays:**

```asm
; Get category name
mov  esi, OFFSET catNames       ; catNames = [addr1, addr2, addr3]
mov  eax, catChoice             ; e.g., 2 (Mathematics)
dec  eax                        ; Convert 1-based → 0-based (2 → 1)
mov  edx, [esi + eax * 4]      ; EDX = catNames[1] = addr of "Mathematics"
call WriteString                ; Print "Mathematics"

; Get difficulty name (same pattern)
mov  esi, OFFSET diffNames      ; diffNames = [addr1, addr2, addr3]
mov  eax, diffChoice            ; e.g., 3 (Hard)
dec  eax                        ; 3 → 2
mov  edx, [esi + eax * 4]      ; EDX = diffNames[2] = addr of "Hard"
call WriteString                ; Print "Hard"
```

### 6.15 `ShowInstructions` & `ShowAbout`

Both follow the same simple pattern: clear screen, display colored header, display text lines, wait for keypress, return.

### 6.16 `ReplayMenu` — Post-Quiz Options

**Lines 1483-1518**

Returns a choice (1, 2, or 3) in EAX. The `main` procedure uses this to decide:
- **1** → `jmp doStartQuiz` — restart quiz flow (new category/difficulty)
- **2** → `jmp mainMenuLoop` — back to main menu
- **3** → `jmp doExit` — exit program

### 6.17 `ExitProgram` — Goodbye & Terminate

**Lines 1522-1560**

```asm
ExitProgram PROC
    call ClearScreen
    ; Display goodbye messages...
    exit                    ; ← Irvine32 macro
ExitProgram ENDP
```

`exit` is an Irvine32 macro that expands to `INVOKE ExitProcess, 0`, which tells Windows to terminate the process immediately.

---

## 7. Key Concepts Summary

### 7.1 Register Usage Throughout the Program

| Register | Primary Usage |
|---|---|
| **EAX** | Function return values, color codes, numbers to print (`WriteDec`), random range input/output, multiplication/division |
| **EBX** | Temporary storage (correct answer character, pointer for usedQuestions array) |
| **ECX** | Loop counter (for `LOOP` instruction and manual loops in quiz), max length for `ReadString` |
| **EDX** | String pointer for `WriteString` / `ReadString`, upper 32 bits for `MUL`/`DIV` |
| **ESI** | Base address of pointer arrays for indexed access (`[esi + eax*4]`) |
| **AL** | Character I/O (`ReadChar` / `WriteChar`), byte operations, flag storage |
| **BL** | Byte comparisons (correct answer character from answers array) |

### 7.2 Irvine32 Functions Used

| Function | Input | Output | Purpose |
|---|---|---|---|
| `Clrscr` | — | — | Clear the console screen |
| `SetTextColor` | EAX = color code | — | Change text foreground/background color |
| `WriteString` | EDX = string address | — | Print a null-terminated string |
| `ReadString` | EDX = buffer addr, ECX = max | — | Read a line from keyboard (until Enter) |
| `WriteDec` | EAX = unsigned number | — | Print an unsigned decimal integer |
| `ReadChar` | — | AL = character | Read a single keystroke (no echo) |
| `WriteChar` | AL = character | — | Print a single character |
| `Crlf` | — | — | Print newline (carriage return + line feed) |
| `Randomize` | — | — | Seed the RNG with current system time |
| `RandomRange` | EAX = range (N) | EAX = 0..N-1 | Generate a random integer |

### 7.3 Assembly Concepts Demonstrated

| Concept | Where Used | Example |
|---|---|---|
| **Procedures** (`PROC`/`ENDP`/`call`/`ret`) | All 17 procedures | `call MainMenu` / `ret` |
| **Arrays** (BYTE and DWORD) | `usedQuestions`, `answers`, `allQ`, `allA`–`allD`, `catNames`, `diffNames` | `mov bl, [esi + eax]` |
| **Loops** (`loop` / manual counter) | `clearLoop`, `quizLoop` in StartQuiz | `loop clearLoop`, `dec ecx` / `jg quizLoop` |
| **Conditional jumps** | Menu validation, grade calculation, answer checking | `je`, `jne`, `jge`, `jb`, `ja`, `jg` |
| **Random number generation** | `RandomQuestionGenerator` | `Randomize` + `RandomRange` |
| **String handling** | Every display procedure | `WriteString`, `ReadString` |
| **User I/O** | All input procedures | `ReadChar`, `WriteChar`, `WriteDec` |
| **Modular programming** | Separate procedures for each task | Each PROC does one thing |
| **Stack operations** (`push`/`pop`) | Saving ECX in quiz loop, saving EAX in GetAnswer | `push ecx` ... `pop ecx` |
| **Pointer arithmetic** | Array indexing | `[esi + eax * 4]` for DWORDs |
| **Bitwise operations** | Clearing registers | `xor al, al` (sets AL to 0) |
| **Arithmetic** | Score calculation, ASCII conversion, percentage | `mul`, `div`, `imul`, `sub`, `add` |
| **Data types** | BYTE arrays vs DWORD arrays | `answers` (1 byte each) vs `allQ` (4 bytes each) |

### 7.4 Jump Instructions Used

| Instruction | Meaning | Used For |
|---|---|---|
| `je` | Jump if Equal | Menu choice matching, answer comparison |
| `jne` | Jump if Not Equal | Wrong answer path |
| `jge` | Jump if Greater or Equal | Grade thresholds (≥ 90, ≥ 80, etc.) |
| `jb` | Jump if Below (unsigned) | Input validation (char < '1') |
| `ja` | Jump if Above (unsigned) | Input validation (char > '4') |
| `jg` | Jump if Greater (signed) | Quiz loop continuation |
| `jmp` | Unconditional Jump | Menu navigation, retry loops |

---

## 8. Data Flow Diagram

```text
[ User Input ]                        [ Global Variables ]                      [ Output ]
  Name           ------------------->   userName           ------------------->   Result Screen
  Menu choice    ------------------->   (control flow)                          
                                                                                
  Category       ------------------->   catChoice                               
                                        categoryBase       ------------------->   Result Screen
                                              |                                 
  Difficulty     ------------------->   diffChoice                              
                                        numQuestions       ------------------->   Result Screen
                                              |                                 
                                              v                                 
                                        currentQIdx        ------------------->   Questions & Options
                                                                                
  Answer         ------------------->   userAnswer         ------------------->   Correct/Wrong Feedback
                                              |                                 
                                              v                                 
                                        lastCorrect                             
                                              |                                 
                                              v                                 
                                        score              ------------------->   Result Screen
                                        correctCount       ------------------->   Result Screen
                                        wrongCount         ------------------->   Result Screen
                                              |                                 
                                              v                                 
                                        percentage         ------------------->   Result Screen
                                        gradePtr           ------------------->   Result Screen
                                        perfPtr            ------------------->   Result Screen
```

---

## 9. How to Build and Run

### Prerequisites

1. **Visual Studio** (any version with C++ Desktop Development)
2. **Irvine32 Library** installed and configured
3. **MASM** assembler (included with Visual Studio)

### Option A: Using Visual Studio Project

1. Create a new **Empty Project** in Visual Studio
2. Set project to build as **MASM** (right-click project → Build Dependencies → Build Customizations → check `masm`)
3. Add `QuizApp.asm` to the project
4. Configure Irvine32 include/library paths in project properties
5. Build and run (F5)

### Option B: Command Line

```
ml /c /coff QuizApp.asm
link /SUBSYSTEM:CONSOLE QuizApp.obj Irvine32.lib kernel32.lib user32.lib
QuizApp.exe
```

> [!NOTE]
> Make sure the Irvine32 include and library directories are in your system PATH or specified with `/I` and `/LIBPATH` flags.

---

*This document was generated as part of the COAL semester project.*
