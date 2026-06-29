
import java.nio.file.Files;
import java.nio.file.Path;

public class BfInterpreter{

    // OLD private char[] tape = new char[30000];  // as per the first original implementation
    private String[] tape;  // represented all as a single String
    private int pc = 0;  // program counter, count instructions
    private int ac = 0;  // array pointer, indexing on tape
    private int[] jumpTable;
    
    private void initJumpTable(String sourceCode){
	//STUB
    }

    private void runInterpreter (String sourceCode){
	//STUB
    }

    private String readSourceCode(String filePath){

	String content;
	try {
	    content = Files.readString(Path.of(filePath));
	} catch (NoSuchFileException e) {
	    System.out.println("Missing file error: " + e);
	} catch (IOException e) {
	    System.out.println("Error: " + e);
	}

	return content;
    }
    
    public static void main (String[] args){
	//STUB
    }
}
