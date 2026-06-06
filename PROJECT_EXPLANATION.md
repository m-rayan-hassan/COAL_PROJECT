# Quiz Application — Simple Project Explanation

This document provides a simple, easy-to-understand explanation of how the MASM Quiz Application works.

## 1. Overall Architecture

The program is built using a simple procedural architecture. There are no complex objects or structures; instead, the program uses **Global Variables** and **Arrays** to manage the game state.

**The Three Main Components:**
1. **Data Section:** Stores the user's score, name, the 30 questions, options, correct answers, and pointer arrays to easily access text.
2. **Game Logic (17 Procedures):** Small, focused functions that handle specific tasks like showing a menu, getting user input, or checking an answer.
3. **Irvine32 Library:** Used for all input and output (e.g., `WriteString` for text, `ReadChar` for keys, `SetTextColor` for colors).

## 2. Program Workflow (How It Runs)

When you run the game, it follows this exact path:

```text
[ Start ]
   |
   v
[ Welcome Screen & Get Name ]
   |
   v
[ Main Menu ] ---> (Select Instructions / About / Exit)
   |
   v
[ Select Category (CS, Math, GK) ]
   |
   v
[ Select Difficulty (Easy, Medium, Hard) ]
   |
   v
[ QUIZ LOOP ] <-----------------------------------+
   |                                              |
   |-- 1. Pick a random, unused question          |
   |-- 2. Display the question and 4 options      |
   |-- 3. Ask user for their answer (A/B/C/D)     |
   |-- 4. Check if the answer is correct          |
   |-- 5. Update score (Add 10 points if right)   |
   |-- 6. Check if more questions remain ---------+
   v
[ Show Final Result & Grade ]
   |
   v
[ Play Again or Exit ]
```

## 3. How the Core Logic Works

The most important part of the code is how questions are displayed, checked, and scored. Here is a simple breakdown of how that happens in the Assembly code, complete with the relevant code snippets.

### Step A: Displaying the Question and Options
Because questions are text strings of different lengths, we cannot use simple math to jump from one question string to another. Instead, we use **Pointer Arrays**.
* `allQ` is an array that stores the memory addresses of all 30 questions.

```asm
; Display the question text
mov  esi, OFFSET allQ          ; ESI = base address of question pointer array
mov  eax, currentQIdx          ; EAX = current question index (e.g., 3)
mov  edx, [esi + eax * 4]      ; EDX = grabs the address of question 3
call WriteString               ; Prints the question on the screen
```
*We use `eax * 4` because each memory address (pointer) is 4 bytes long.* The program repeats this exact same process for the option arrays (`allA`, `allB`, `allC`, `allD`) to print the options below the question.

### Step B: Getting the User's Answer
The procedure `GetAnswer` uses the `ReadChar` function to capture a single keystroke from the user. 

```asm
call ReadChar                  ; Reads a single character into the AL register
    
; Convert lowercase to uppercase
cmp  al, 'a'                   ; Is it a lowercase letter?
jb   noConvert
cmp  al, 'z'
ja   noConvert
sub  al, 32                    ; 'a' (97) - 32 = 'A' (65)
noConvert:

; Validate input
cmp  al, 'A'
je   validAnswer               ; If A, B, C, or D, jump to validAnswer
cmp  al, 'B'
je   validAnswer
; ... checks for C and D ...
```
* It automatically converts lowercase letters to uppercase (by subtracting 32 from the ASCII value).
* It checks if the letter is A, B, C, or D. The valid answer letter is stored in a global variable called `userAnswer`.

### Step C: Comparing the Answer
We have a simple byte array called `answers` that holds the correct letter for every single question:

```asm
; Get the correct answer from the array
mov  esi, OFFSET answers       ; ESI = base of answers array
mov  eax, currentQIdx          ; EAX = question index
mov  bl, [esi + eax]           ; BL = correct answer character (e.g. 'B')

; Compare with user's answer
mov  al, userAnswer            ; AL = what the user typed
cmp  al, bl                    ; Compare the two
je   answerCorrect             ; If they match, jump to Correct code
```
1. It looks at the `answers` array at the current question index to find the correct letter.
2. It uses the `cmp` (compare) instruction to match the correct letter against the `userAnswer` variable.
3. If they match, it sets a flag `lastCorrect = 1`. If they don't, it sets `lastCorrect = 0`.

### Step D: Marking and Storing the Score
Immediately after checking the answer, the `UpdateScore` procedure runs to manage the math:

```asm
cmp  lastCorrect, 1            ; Was the last answer correct?
jne  wasWrong                  ; If not equal, jump to wasWrong

; Correct Answer path:
add  score, PTS_CORRECT        ; Add 10 points to total score
inc  correctCount              ; Increment correct answer count
ret

wasWrong:
; Wrong Answer path:
inc  wrongCount                ; Increment wrong answer count
ret
```

### Step E: Preventing Repeated Questions
To ensure the user doesn't get the same question twice in one quiz session, we use a tracking array called `usedQuestions`.

```asm
tryAgain:
mov  eax, 10                   ; We want a random number between 0 and 9
call RandomRange               ; Generates the random number in EAX

lea  ebx, usedQuestions        ; Point EBX to the tracking array
cmp  BYTE PTR [ebx + eax], 1   ; Check if this question is already marked as used
je   tryAgain                  ; If it is 1 (used), jump back and generate a new number

mov  BYTE PTR [ebx + eax], 1   ; If it is 0, mark it as 1 (used) now
```
Every time the random number generator picks a question, it checks the array. If the spot contains `1`, the game loops back (`tryAgain`) until it finds a question marked `0`.

### Step F: Final Grading and Results
After the quiz loop finishes all its questions, the `CalculateGrade` procedure calculates the percentage using basic multiplication and division:

```asm
; Formula: percentage = (score * 100) / maxScore
xor  edx, edx           ; Clear EDX before multiplication
mov  eax, score         
mov  ebx, 100
mul  ebx                ; Multiply score by 100 (Result in EDX:EAX)
mov  ebx, maxScore      
div  ebx                ; Divide result by maxScore -> percentage stored in EAX
```

It then uses `cmp` (compare) and `jge` (jump if greater or equal) instructions to determine the grade:

```asm
cmp  eax, 90            ; Is percentage >= 90?
jge  isAPlus            ; Yes -> give A+
cmp  eax, 80            ; Is percentage >= 80?
jge  isA                ; Yes -> give A
```

Finally, the `ShowResult` procedure prints out all the stored global variables (`userName`, `score`, `correctCount`, `wrongCount`, percentage, and grade) on a neatly formatted final screen.
