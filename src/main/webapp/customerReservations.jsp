<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page language="java" import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="ISO-8859-1">
    <title>Customer Reservations</title>
</head>
<body>
    <h1>Customer Reservation Management</h1>

    <!-- Make a Reservation -->
    <h2>Make a Reservation</h2>
<form method="post" action="makeReservation.jsp">
    <!-- Route Selection -->
    <label for="route">Select Route:</label>
    <select name="route" id="route" onchange="location.href='customerReservations.jsp?route=' + this.value;" required>
        <option value="">-- Select a Route --</option>
        <%
            ApplicationDB db = new ApplicationDB();
            Connection conn = db.getConnection();
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT DISTINCT name FROM TransitLine");
            String selectedRoute = request.getParameter("route");

            while (rs.next()) {
                String routeName = rs.getString("name");
        %>
        <option value="<%= routeName %>" <%= routeName.equals(selectedRoute) ? "selected" : "" %>><%= routeName %></option>
        <%
            }
            rs.close();
            stmt.close();
        %>
    </select>
    <br>

    <!-- Trip Type Selection -->
    <label for="type">Trip Type:</label>
    <select name="type" id="type" onchange="location.href='customerReservations.jsp?route=<%= selectedRoute %>&type=' + this.value;" required>
        <option value="">-- Select Trip Type --</option>
        <option value="two-way" <%= "two-way".equals(request.getParameter("type")) ? "selected" : "" %>>Two-Way</option>
        <option value="one-way" <%= "one-way".equals(request.getParameter("type")) ? "selected" : "" %>>One-Way</option>
    </select>
    <br>

    <!-- Stops Selection (Visible Only for One-Way Trips) -->
    <%
        String tripType = request.getParameter("type");
        if ("one-way".equals(tripType) && selectedRoute != null && !selectedRoute.isEmpty()) {
    %>
    <label for="originStop">Select Origin Stop:</label>
    <select name="originStop" id="originStop" required>
        <%
            PreparedStatement stopStmt = conn.prepareStatement(
                "SELECT rs.sid, s.name AS stationName FROM RouteStops rs JOIN Station s ON rs.sid = s.sid WHERE rs.name = ? ORDER BY rs.aTime"
            );
            stopStmt.setString(1, selectedRoute);
            ResultSet stopRs = stopStmt.executeQuery();

            while (stopRs.next()) {
                String sid = stopRs.getString("sid");
                String stationName = stopRs.getString("stationName");
        %>
        <option value="<%= sid %>"><%= stationName %></option>
        <%
            }
            stopRs.close();
            stopStmt.close();
        %>
    </select>
    <br>

    <label for="destinationStop">Select Destination Stop:</label>
    <select name="destinationStop" id="destinationStop" required>
        <%
            stopStmt = conn.prepareStatement(
                "SELECT rs.sid, s.name AS stationName FROM RouteStops rs JOIN Station s ON rs.sid = s.sid WHERE rs.name = ? ORDER BY rs.aTime"
            );
            stopStmt.setString(1, selectedRoute);
            stopRs = stopStmt.executeQuery();

            while (stopRs.next()) {
                String sid = stopRs.getString("sid");
                String stationName = stopRs.getString("stationName");
        %>
        <option value="<%= sid %>"><%= stationName %></option>
        <%
            }
            stopRs.close();
            stopStmt.close();
        %>
    </select>
    <br>
    <% } %>

    <!-- Discount Type -->
    <label for="discountType">Passenger Type (Discount):</label>
    <select name="discountType" id="discountType" required>
        <option value="none" <%= "none".equals(request.getParameter("discountType")) ? "selected" : "" %>>None</option>
        <option value="child" <%= "child".equals(request.getParameter("discountType")) ? "selected" : "" %>>Child (25% Off)</option>
        <option value="elder" <%= "elder".equals(request.getParameter("discountType")) ? "selected" : "" %>>Elder (35% Off)</option>
        <option value="disabled" <%= "disabled".equals(request.getParameter("discountType")) ? "selected" : "" %>>Disabled (50% Off)</option>
    </select>
    <br>

    <!-- Passenger Details -->
    <label for="passenger">Passenger Name:</label>
    <input type="text" name="passenger" id="passenger" required>
    <br>
    <input type="submit" value="Make Reservation">
</form>



    <!-- View Reservations -->
    <h2>View Reservations</h2>
    <form method="get" action="viewReservations.jsp">
        <label for="username">Enter Username:</label>
        <input type="text" name="username" id="username" required>
        <br>
        <input type="submit" value="View Reservations">
    </form>

    <!-- Browse Train Schedules -->
    <a href="browseSchedules.jsp" style="text-decoration: none; color: blue; font-size: 18px;">
        Browse Train Schedules
    </a>
</body>
</html>
