<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*"%>
<%
    String username = request.getParameter("username");
    String resNumberToCancel = request.getParameter("resNumber");

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        ApplicationDB db = new ApplicationDB();
        conn = db.getConnection();

        // Handle reservation cancellation
        if (resNumberToCancel != null && !resNumberToCancel.isEmpty()) {
            PreparedStatement cancelStmt = conn.prepareStatement("DELETE FROM Reservation WHERE resNumber = ?");
            cancelStmt.setString(1, resNumberToCancel);
            int rowsAffected = cancelStmt.executeUpdate();
            cancelStmt.close();

            if (rowsAffected > 0) {
                out.println("<h3>Reservation " + resNumberToCancel + " has been successfully canceled.</h3>");
            } else {
                out.println("<h3>Failed to cancel reservation " + resNumberToCancel + ".</h3>");
            }
        }

        // Display reservations for the user
        if (username != null && !username.isEmpty()) {
            stmt = conn.prepareStatement(
                "SELECT r.resNumber, r.date, r.totalFare, r.line " +
                "FROM Reservation r " +
                "WHERE r.passenger = ?"
            );
            stmt.setString(1, username);
            rs = stmt.executeQuery();

            out.println("<h3>Reservations for " + username + ":</h3>");
            out.println("<table border='1'>");
            out.println("<tr><th>Reservation Number</th><th>Date</th><th>Total Fare</th><th>Train Line</th><th>Action</th></tr>");
            while (rs.next()) {
                String resNumber = rs.getString("resNumber");
                String line = rs.getString("line"); // Fetch the train line
                out.println("<tr>");
                out.println("<td>" + resNumber + "</td>");
                out.println("<td>" + rs.getDate("date") + "</td>");
                out.println("<td>$" + rs.getDouble("totalFare") + "</td>");
                out.println("<td>" + line + "</td>");
                out.println("<td>");
                out.println("<form method='post' action='' style='display:inline;'>");
                out.println("<input type='hidden' name='username' value='" + username + "'>");
                out.println("<input type='hidden' name='resNumber' value='" + resNumber + "'>");
                out.println("<input type='submit' value='Cancel'>");
                out.println("</form>");
                out.println("</td>");
                out.println("</tr>");
            }
            out.println("</table>");
        }
    } catch (Exception e) {
        e.printStackTrace(new PrintWriter(out)); // Use PrintWriter for stack trace
        out.println("<h3>Error occurred while processing your request.</h3>");
    } finally {
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
%>
<a href="customerReservations.jsp">Back to Reservations</a>
