import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Scanner;

public class dbManager {
	private Connection conn;
	private Statement stat;
	
	public dbManager(){
		try {
			Class.forName("org.postgresql.Driver");
			System.out.println("Driver Found!");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver not found!");
		}
	}
	
	public void connect() {
		String url = "jdbc:postgresql://localhost:5432/PhaseA";
		String username = "postgres";
		String password = "Mvzia2002";
		
		try {
			conn = DriverManager.getConnection(url, username, password);
			System.out.println("Connection established : "+conn);
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void disconnect() throws SQLException {
		if(conn != null && !conn.isClosed()) {
			conn.close();
			System.out.println("Disconnected from the database");
		}
	}

	public void displayStudentGrade() throws SQLException {
		Scanner scn = new Scanner(System.in);
		System.out.println("Enter the student's amka: ");
		String amka = scn.nextLine();
		
		System.out.println("Enter the course's code: ");
		String courseCode = scn.nextLine();
		
		String query = "SELECT amka, course_code, final_grade from \"Register\" " +
                	   "WHERE amka="+ "\'"+ amka.toString()+ "\'"+ 
                	   "AND course_code="+ "\'"+ courseCode.toString()+ "\'";
		
		try(PreparedStatement pst = conn.prepareStatement(query)){
			
			ResultSet res = pst.executeQuery();
			
			if(res.next()) {
				int finalGrade = res.getInt("final_grade");
				
				System.out.println("Final Grade: "+finalGrade);
			}else {
				System.out.println("There was not found grade for the student with amka "+amka+
						" and the course code "+courseCode);
			}
		}
	}
	
	public void updateGrade() throws SQLException {
		Scanner scn = new Scanner(System.in);
		System.out.println("Enter the student's amka: ");
		String amka = scn.nextLine();
		
		System.out.println("Enter course code: ");
		String courseCode = scn.nextLine();
		
		System.out.println("Enter the serial number: ");
		int serialNumber = scn.nextInt();
		
		System.out.println("Enter the exam grade: ");
		int examGrade = scn.nextInt();
		
		System.out.println("Enter the lab grade: ");
		int labGrade = scn.nextInt();
		
		String query =  "UPDATE \"Register\" SET exam_grade = ?, lab_grade = ? " +
                		"WHERE amka = ? AND course_code = ? AND serial_number = ?";
		
		try(PreparedStatement pst = conn.prepareStatement(query)){
			pst.setInt(1, examGrade);
			pst.setInt(2, labGrade);
			pst.setString(3, amka);
			pst.setString(4, courseCode);
			pst.setInt(5, serialNumber);
			
			int rowsAffected = pst.executeUpdate();
			
			if(rowsAffected > 0) {
				System.out.println("The grade has been updated successfully.");
			}else {
				System.out.println("Failed grade update.");
			}
		}	
	}
	
	public void searchPerson() throws SQLException {
		Scanner scn = new Scanner(System.in);
		System.out.println("Insert the first initials of the person's last name:");
		String lastNameInitials = scn.nextLine();
		
		String query = "SELECT * FROM \"Person\" WHERE surname LIKE ?";

		
		try(PreparedStatement pst = conn.prepareStatement(query)){
			pst.setString(1, lastNameInitials + "%");
			
			ResultSet res = pst.executeQuery();
			
			int pageSize = 5;
			int pageNumber = 1;
			int rowCount = 0;
			
			while(res.next()) {
				rowCount++;
				
				if(rowCount > pageSize) {
					System.out.println("Press 'n' for the next page, or insert the page number: ");
					Scanner scanner = new Scanner(System.in);
					String input = scanner.nextLine();
					
					if(input.equals("n")) {
						pageNumber++;
						rowCount = 1;
						continue;
					}else {
						try {
							pageNumber = Integer.parseInt(input);
							rowCount = 1;
						}catch(NumberFormatException e) {
							System.out.println("Wrong input. Shows the first 5 results.");
							break;
						}
					}
				}
				String lastName = res.getString("surname");
				String firstName = res.getString("name");
				
				System.out.println(lastName+ " " +firstName);
			}
			
			System.out.println("Page: "+pageNumber);
		}
	}
	
	public void getDetailedStudentGrades() throws SQLException {
		Scanner scn = new Scanner(System.in);
		System.out.println("Insert student's amka:");
		String amka = scn.nextLine();	
		String query = "SELECT amka, course_title, exam_grade, lab_grade FROM \"Register\" " +
	               "JOIN \"Course\" ON \"Register\".course_code = \"Course\".course_code " +
	               "WHERE amka = '" + amka.toString() + "' ORDER BY typical_year";

		try(PreparedStatement pst = conn.prepareStatement(query)){
			
			ResultSet res = pst.executeQuery();
			
			while(res.next()) {
				String courseTitle = res.getString("course_title");
				int examGrade = res.getInt("exam_grade");
				int labGrade = res.getInt("lab_grade");
				
				System.out.println("Course: "+courseTitle);
				System.out.println("Exam Grade: "+examGrade);
				System.out.println("Lab Grade: "+labGrade);
			}
		}
	}

}

