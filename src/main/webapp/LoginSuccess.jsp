<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
		<title>LOGIN SUCCESS PAGE</title>
	</head>
	<body>
<%

String fName = "";
String lName = "";
String username = "";
String password = "";
String email = "";

if("LOGIN".equals(request.getParameter("action"))) {
	try {
		  // Get the database connection
		  ApplicationDB db = new ApplicationDB();
		  Connection con = db.getConnection();
		  // Get the user inputs from the form
		  username = request.getParameter("username");
		  password = request.getParameter("password");
		  // Use PreparedStatement to prevent SQL injection
		  String query = "SELECT * FROM Users WHERE username = ? AND password = ?";
		  PreparedStatement pstmt = con.prepareStatement(query);
		  pstmt.setString(1, username);
		  pstmt.setString(2, password);
		  // Execute the query
		  ResultSet result = pstmt.executeQuery();
		   String messege;
		  if (result.next()) {
		      messege = "LOGIN SUCCESSFUL";
		      fName = result.getString("fName");
		      lName = result.getString("lName");
		  } else {
		      String errorMsg = "Invalid username or password. Please try again.";
		      response.sendRedirect("Login.jsp?errorMessage=" + java.net.URLEncoder.encode(errorMsg, "UTF-8"));
		      return;
		  
		  }
		  // Close resources
		  result.close();
		  pstmt.close();
		  con.close();
		   out.println("<h1>" + messege + "</h1>");
		   out.println("<h2>" + "Hello " + fName + " " + lName + "!" + "</h2>");
		} catch (Exception e) {
		  out.println("An error occurred: " + e.getMessage());
		}
}
else if("CREATE".equals(request.getParameter("action"))) {
	out.println("yay");
}

%>

<form action="Login.jsp" method="get">
   <button type="submit">Logout</button>
</form>
	
	</body>
</html>
