import java.sql.SQLException;
import java.util.Scanner;

public class Application {
	
	public static void showMenu(dbManager manager) throws SQLException {
		System.out.println("------------MENU-----------");
		System.out.println("\n1. Print student's grade according to his amka and course code");
		System.out.println("\n2. Update grades according to a student's amka, course code and serial number");
		System.out.println("\n3. Search person based on his last name's initial ");
		System.out.println("\n4. Print detailed grades of a student");
		System.out.println("\n0. EXIT");
		
		Scanner scn = new Scanner(System.in);
		int choice = scn.nextInt();
		
		switch(choice) {
		case 1:
			showStudentGrades(manager);
			break;
		case 2:
			updateGrade(manager);
			break;
		case 3:
			searchPerson(manager); 
			break;
		case 4:
			printDetailedStudentGrades(manager);
			break;
		case 0:
			return;
		default:
			System.out.println("Not valid choice. Please, try again.");
			showMenu(manager);
		}
	}
	
	public static void showStudentGrades(dbManager manager) throws SQLException {
		manager.displayStudentGrade();
		showMenu(manager);
	}
	
	public static void updateGrade(dbManager manager) throws SQLException {
		manager.updateGrade();
		showMenu(manager);
	}
	
	public static void searchPerson(dbManager manager) throws SQLException {
		manager.searchPerson();
		showMenu(manager);
	}
	
	public static void printDetailedStudentGrades(dbManager manager) throws SQLException {
		manager.getDetailedStudentGrades();
		showMenu(manager);
	}

	public static void main(String[] args) {
		dbManager manager = new dbManager();
		
		try {
			//Connect with database
			manager.connect();
			
			showMenu(manager);
			
			//Disconnect from the database
			manager.disconnect();
		} catch (SQLException e) {
			e.printStackTrace();
		}

	}

}
