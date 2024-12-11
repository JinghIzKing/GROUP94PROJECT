<%@ page language="java" import="java.sql.*" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*"%>
<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page language="java" import="java.sql.*" %>
<!DOCTYPE html>
<html>
<a href="customerReservations.jsp" style="text-decoration: none; color: blue; font-size: 18px;">
    Go to Customer Reservations
</a>

<head>
    <title>Browse and Search Train Schedules</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            text-align: center;
            padding: 10px;
        }
    </style>
</head>
<body>
    <h1>Browse and Search Train Schedules</h1>

    <!-- Search Form -->
    <form method="get" action="browseSchedules.jsp">
        <label for="origin">Origin:</label>
        <select name="origin" id="origin">
            <option value="">-- Select Origin --</option>
            <% 
                Connection conn = null;
                PreparedStatement stmt = null;
                ResultSet rs = null;
                try {
                    ApplicationDB db = new ApplicationDB();
                    conn = db.getConnection();
                    stmt = conn.prepareStatement("SELECT DISTINCT origin FROM TransitLine ORDER BY origin");
                    rs = stmt.executeQuery();
                    while (rs.next()) {
                        String origin = rs.getString("origin");
                        out.println("<option value='" + origin + "'>" + origin + "</option>");
                    }
                } finally {
                    if (rs != null) rs.close();
                    if (stmt != null) stmt.close();
                    if (conn != null) conn.close();
                }
            %>
        </select>
        <br>

        <label for="destination">Destination:</label>
        <select name="destination" id="destination">
            <option value="">-- Select Destination --</option>
            <% 
                Connection connDestination = null;
                PreparedStatement stmtDestination = null;
                ResultSet rsDestination = null;
                try {
                    ApplicationDB db = new ApplicationDB();
                    connDestination = db.getConnection();
                    stmtDestination = connDestination.prepareStatement("SELECT DISTINCT destination FROM TransitLine ORDER BY destination");
                    rsDestination = stmtDestination.executeQuery();
                    while (rsDestination.next()) {
                        String destination = rsDestination.getString("destination");
                        out.println("<option value='" + destination + "'>" + destination + "</option>");
                    }
                } finally {
                    if (rsDestination != null) rsDestination.close();
                    if (stmtDestination != null) stmtDestination.close();
                    if (connDestination != null) connDestination.close();
                }
            %>
        </select>
        <br>

        <label for="date">Date:</label>
        <input type="date" name="date" id="date">
        <br>

        <label for="sort">Sort By:</label>
        <select name="sort" id="sort">
            <option value="originTime">Departure Time</option>
            <option value="destTime">Arrival Time</option>
            <option value="baseFare">Fare</option>
        </select>
        <br>

        <input type="submit" value="Search">
    </form>

    <!-- Results Section -->
    <h2>Train Schedules</h2>
    <table>
        <tr>
            <th>Route Name</th>
            <th>Origin</th>
            <th>Destination</th>
            <th>Departure Time</th>
            <th>Arrival Time</th>
            <th>Base Fare</th>
            <th>Stops</th>
        </tr>
        <%
            // Retrieve search parameters
            String searchOrigin = request.getParameter("origin");
            String searchDestination = request.getParameter("destination");
            String searchDate = request.getParameter("date");
            String sortBy = request.getParameter("sort");

            // Build the query
            String query = "SELECT * FROM TransitLine";
            String whereClause = "";
            if (searchOrigin != null && !searchOrigin.isEmpty()) {
                whereClause += " origin = '" + searchOrigin + "'";
            }
            if (searchDestination != null && !searchDestination.isEmpty()) {
                if (!whereClause.isEmpty()) whereClause += " AND";
                whereClause += " destination = '" + searchDestination + "'";
            }
            if (searchDate != null && !searchDate.isEmpty()) {
                if (!whereClause.isEmpty()) whereClause += " AND";
                whereClause += " DATE(originTime) = '" + searchDate + "'";
            }
            if (!whereClause.isEmpty()) query += " WHERE " + whereClause;
            if (sortBy != null && !sortBy.isEmpty()) {
                query += " ORDER BY " + sortBy;
            }

            try {
                ApplicationDB db = new ApplicationDB();
                conn = db.getConnection();
                stmt = conn.prepareStatement(query);
                rs = stmt.executeQuery();
                while (rs.next()) {
                    String name = rs.getString("name");
                    String origin = rs.getString("origin");
                    String destination = rs.getString("destination");
                    String originTime = rs.getString("originTime");
                    String destTime = rs.getString("destTime");
                    float baseFare = rs.getFloat("baseFare");

                    // Fetch stops
                    PreparedStatement stopStmt = conn.prepareStatement(
                        "SELECT s.name FROM RouteStops rs JOIN Station s ON rs.sid = s.sid WHERE rs.name = ? ORDER BY rs.aTime"
                    );
                    stopStmt.setString(1, name);
                    ResultSet stopRs = stopStmt.executeQuery();
                    StringBuilder stops = new StringBuilder();
                    while (stopRs.next()) {
                        stops.append(stopRs.getString("name")).append(", ");
                    }
                    stopRs.close();
                    stopStmt.close();

                    // Remove trailing comma from stops
                    if (stops.length() > 0) stops.setLength(stops.length() - 2);

                    out.println("<tr>");
                    out.println("<td>" + name + "</td>");
                    out.println("<td>" + origin + "</td>");
                    out.println("<td>" + destination + "</td>");
                    out.println("<td>" + originTime + "</td>");
                    out.println("<td>" + destTime + "</td>");
                    out.println("<td>$" + baseFare + "</td>");
                    out.println("<td>" + stops + "</td>");
                    out.println("</tr>");
                }
            } finally {
                if (rs != null) rs.close();
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            }
        %>
    </table>
</body>
</html>
