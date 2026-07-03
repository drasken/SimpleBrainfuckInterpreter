import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.HashMap;
// TODO: decide wich to use in temp stack for jump table
import java.util.LinkedList;
import java.util.ArrayDeque;
import java.util.Deque;
//
import java.io.IOException;
import java.nio.file.NoSuchFileException;


/**
   This class implement a simple Brainfuck interpreter.
*/
public class BfInterpreter{
    
    // All fields to encapsulate the interpreter state
    private int[] tape;  // represented as an array of bytes
    private static final int TAPE_LENGTH = 30000;  // standard tape length per the original spec
    private char[] sourceCode;
    private int pc = 0;  // program counter, count instructions
    private int ac = 0;  // array pointer, indexing on tape
    private Map<Integer, Integer> jumpTable;  // used to save indexes of code's brackets 


    public BfInterpreter(String sourceCode) {
	this.tape = new int[TAPE_LENGTH];
	this.sourceCode = readSourceCode(sourceCode);
	this.jumpTable =  makeJumpTable(sourceCode);
    }


    /**
       Method used to read the BF source code to execute. 
    */
    private char[] readSourceCode(String filePath) {

	try {
	    content = Files.readString(Path.of(filePath));
	} catch (NoSuchFileException e) {
	    throw new RuntimeException("Source file not found: " + filePath, e);
	} catch (IOException e) {
	    throw new RuntimeException("Could not read source file: " + filePath, e);
	}

	return content.toCharArray();
    }
    


    /**
       Method to pre-parse the source code and make a "jump table".
       Each pair of nested bracket is saved as pair of corresponding indexes:
       to each opening [ of pos x and the corresponding ] of pos y
       a pair x: y is saved and vice versas
    */
    private Map<Integer, Integer> makeJumpTable(String sourceCode) {
	
	LinkedList<Integer> myStack = new LinkedList<>();  // Used as a temporary "stack" 
	int pos = 0;  // keep track of the char index
	Map<Integer, Integer> res = new HashMap<>();

	for (char c : sourceCode.toCharArray()){
	    if (c == '[') {
		myStack.addLast(pos);
		pos++;
	    } else if (c == ']') {
		if (myStack.isEmpty()) {
		    throw new IllegalArgumentException("Unmatched ']' at position " + pos);
		}
		// first add pos for [
		res.put(myStack.getLast(), pos);
		// second add pos for ]
		res.put(pos, myStack.removeLast());
		// increment index
		pos++;
	    } else {
		pos++;
	    }
	}

	// Safeguard, check if stack is empty
	if (!myStack.isEmpty()) {
	    throw new IllegalArgumentException("Unmatched '[' in source");
	}
	return res;
    }


    /**
       Core function used to implement the execution logic for all the 8 commands
    */
    private void runInterpreter (String sourceCode) {
	// I initially start by creating the jump table to use for the jump instructions
	this.jumpTable =  makeJumpTable(sourceCode);

	// Run the code until all instructions are executed
	while (this.pc < this.tape.length) {
	    char instruction = this.sourceCode[this.pc];
	    // TODO: finish implement cases
	    switch (instruction) {
		// inc/dec instructions
	    case  '+':
		this.ac++;
		this.pc++;
		break;
	    case  '-':
		this.ac--;		
		this.pc++;
		break;
		// movements instructions
	    case  '<':
		if (this.ac < (TAPE_LENGTH - 1) {
			this.ac++;
			this.pc++;
		    } else {
			throw new Exception("Pointer Overflow");
		    }		    
		    break;
		    case  '>':
		    if (this.ac > 0) {
			    this.ac--;
			    this.pc++;
			} else {
			    throw new Exception("Pointer Underflow");
			}		    
			break;
			// print/read instructions
			case  '.':
			break;
			case  ',':
			break;
			// jump instructions
			case  '[':		
			break;
			case  ']':
			break;
			// ignore every other characters
			default:
			continue;
			}
		    }
	    }


    public static void main (String[] args) {
	//STUB
    }
}
