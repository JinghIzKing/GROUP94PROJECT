<%@ page import="java.io.*,java.util.*,java.sql.*" %>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="com.cs336.pkg.ApplicationDB" %>
<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page session="true" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) {
        username = "placeholder";
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    // Handle cancel request
    String cancelResNumber = request.getParameter("cancelResNumber");
    if (cancelResNumber != null && !cancelResNumber.isEmpty()) {
        try {
            ApplicationDB db = new ApplicationDB();
            conn = db.getConnection();
            System.out.println("Database connection established for cancellation.");

            String cancelQuery = "DELETE FROM reservation WHERE resNumber = ? AND username = ?";
            stmt = conn.prepareStatement(cancelQuery);
            stmt.setString(1, cancelResNumber);
            stmt.setString(2, username);
            int rowsAffected = stmt.executeUpdate();

            if (rowsAffected > 0) {
                out.println("<h3>Reservation " + cancelResNumber + " canceled successfully.</h3>");
            } else {
                out.println("<h3>Error: Unable to cancel reservation " + cancelResNumber + ". Please try again.</h3>");
            }

            stmt.close();
        } catch (Exception e) {
            e.printStackTrace(new PrintWriter(out));
            out.println("<h3>Error occurred while canceling the reservation. Please try again later.</h3>");
        } finally {
            if (conn != null) conn.close();
        }
    }

    // Fetch reservations for the logged-in user
    try {
        ApplicationDB db = new ApplicationDB();
        conn = db.getConnection();
        System.out.println("Database connection established for fetching reservations.");

        String reservationsQuery = """
            SELECT 
                r.resNumber,
                r.date,
                r.totalFare,
                r.passenger,
                r.line,
                sStart.name AS startStation,
                sStop.name AS endStation,
                r.discountType,
                t.tName AS trainName,
                r.aTime,
                r.dTime
            FROM reservation r
            JOIN station sStart ON r.sidStart = sStart.sid
            JOIN station sStop ON r.sidStop = sStop.sid
            JOIN train t ON r.tid = t.tid
            WHERE r.username = ?
            ORDER BY r.date DESC
        """;

        stmt = conn.prepareStatement(reservationsQuery);
        stmt.setString(1, username);
        rs = stmt.executeQuery();
%>
<!DOCTYPE html>
<html>
<head>
    <title>View Reservations</title>
</head>
<body>
    <h1>My Reservations</h1>
    <table border="1">
        <tr>
            <th>Reservation Number</th>
            <th>Date Reserved</th>
            <th>Total Fare</th>
            <th>Passenger Name</th>
            <th>Line</th>
            <th>Start Station</th>
            <th>End Station</th>
            <th>Discount Type</th>
            <th>Train Name</th>
            <th>Arrival Time</th>
            <th>Departure Time</th>
            <th>Action</th>
        </tr>
        <% boolean hasReservations = false; %>
        <% while (rs.next()) { %>
            <% hasReservations = true; %>
            <tr>
                <td><%= rs.getString("resNumber") %></td>
                <td><%= rs.getDate("date") %></td>
                <td>$<%= String.format("%.2f", rs.getFloat("totalFare")) %></td>
                <td><%= rs.getString("passenger") %></td>
                <td><%= rs.getString("line") %></td>
                <td><%= rs.getString("startStation") %></td>
                <td><%= rs.getString("endStation") %></td>
                <td><%= rs.getString("discountType") %></td>
                <td><%= rs.getString("trainName") %></td>
                <td><%= rs.getTimestamp("aTime") %></td>
                <td><%= rs.getTimestamp("dTime") %></td>
                <td>
                    <form action="viewReservations.jsp" method="post" style="display:inline;">
                        <input type="hidden" name="cancelResNumber" value="<%= rs.getString("resNumber") %>">
                        <button type="submit">Cancel</button>
                    </form>
                </td>
            </tr>
        <% } %>
        <% if (!hasReservations) { %>
        <tr>
            <td colspan="12">No reservations found.</td>
        </tr>
        <% } %>
    </table>
    <br>
    <form action="browseSchedules.jsp" method="get">
        <button type="submit">Back to Browse Schedules</button>
    </form>
</body>
</html>
<%
    } catch (Exception e) {
        e.printStackTrace(new PrintWriter(out)); // Debugging
        out.println("<h3>Error occurred while retrieving reservations. Please try again later.</h3>");
    } finally {
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
%>
