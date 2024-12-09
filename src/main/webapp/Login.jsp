<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
   <title>LOGIN PAGE</title>
</head>
<body>
   <% out.println("WELCOME TO THE LOGIN PAGE"); %>
   <!-- Display error message if present -->
   <%
       String errorMessage = request.getParameter("errorMessage");
       if (errorMessage != null) {
   %>
       <p style="color: red;"><%= errorMessage %></p>
   <% } %>
   <form method="post" action="LoginSuccess.jsp">
       <table>
           <tr>
               <td>Username:</td>
               <td><input type="text" name="username"></td>
           </tr>
           <tr>
               <td>Password:</td>
               <td><input type="text" name="password"></td>
           </tr>
       </table>
       <input type="submit" name="action" value="LOGIN">
   </form>
   
   <% out.println("New User? Create an Account!"); %>
      </form>
   <!-- Account Creation Table -->
      <form method="post" action="LoginSuccess.jsp">
       <table>
           <tr>
               <td>Username:</td>
               <td><input type="text" name="username"></td>
           </tr>
           <tr>
               <td>Password:</td>
               <td><input type="text" name="password"></td>
           </tr>
            <tr>
               <td>First Name:</td>
               <td><input type="text" name="fName"></td>
           </tr>
           <tr>
               <td>Last Name:</td>
               <td><input type="text" name="lName"></td>
           </tr>
           <tr>
               <td>Phone Number:</td>
               <td><input type="text" name="phone"></td>
           </tr>
           <tr>
               <td>Date of Birth:</td>
               <td><input type="text" name="dob"></td>
           </tr>
       </table>
       <input type="submit" name="action" value="CREATE">
   </form>
   
   <br>
</body>