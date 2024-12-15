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

    String fName = "Guest";
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    List<String> stationNames = new ArrayList<>();

    String sortBy = request.getParameter("sortBy");
    if (sortBy == null) sortBy = "firstStopTime";
    String origin = request.getParameter("origin");
    String destination = request.getParameter("destination");
    String travelDate = request.getParameter("travelDate");

    try {
        ApplicationDB db = new ApplicationDB();
        conn = db.getConnection();
        System.out.println("Database connection established.");

        // Fetch user's first name
        String userQuery = "SELECT fName FROM user WHERE username = ?";
        stmt = conn.prepareStatement(userQuery);
        stmt.setString(1, username);
        rs = stmt.executeQuery();
        if (rs.next()) {
            fName = rs.getString("fName");
        }
        rs.close();
        stmt.close();

        // Fetch station names for dropdowns
        String stationQuery = "SELECT DISTINCT name FROM station ORDER BY name";
        stmt = conn.prepareStatement(stationQuery);
        rs = stmt.executeQuery();
        while (rs.next()) {
            stationNames.add(rs.getString("name"));
        }
        rs.close();
        stmt.close();

        // Build query
        StringBuilder scheduleQuery = new StringBuilder("""
            SELECT 
                rs.name AS transitLine,
                t.tName AS trainName,
                GROUP_CONCAT(s.name ORDER BY rs.aTime SEPARATOR ' -> ') AS routeStops,
                MIN(rs.aTime) AS firstStopTime,
                MAX(rs.dTime) AS lastStopTime,
                tl.baseFare,
                DATE(rs.aTime) AS travelDate
            FROM routestops rs
            JOIN station s ON rs.sid = s.sid
            JOIN train t ON rs.tid = t.tid
            JOIN transitline tl ON rs.tid = tl.tid AND rs.name = tl.name
            WHERE 1=1
        """);

        // Add filters
        if (travelDate != null && !travelDate.isEmpty()) {
            scheduleQuery.append(" AND DATE(rs.aTime) = ? ");
        }

        // Add grouping and sorting
        scheduleQuery.append("""
            GROUP BY rs.name, t.tName, tl.baseFare, DATE(rs.aTime)
        """);
        scheduleQuery.append(" ORDER BY ").append(sortBy).append(" ");

        System.out.println("Final SQL Query: " + scheduleQuery.toString()); // Debugging log

        stmt = conn.prepareStatement(scheduleQuery.toString());
        int paramIndex = 1;
        if (travelDate != null && !travelDate.isEmpty()) {
            stmt.setString(paramIndex++, travelDate);
        }

        rs = stmt.executeQuery();
        System.out.println("Query executed successfully.");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Browse Train Schedules</title>
</head>
<body>
    <h1>Welcome <%= fName %>!</h1>
    <h2>Train Schedules</h2>

    <!-- Filtering and Sorting Form -->
    <form action="browseSchedules.jsp" method="get">
        <label for="origin">Origin:</label>
        <select name="origin" id="origin">
            <option value="">-- Select Origin --</option>
            <% for (String station : stationNames) { %>
                <option value="<%= station %>" <%= station.equals(origin) ? "selected" : "" %>><%= station %></option>
            <% } %>
        </select>
        <label for="destination">Destination:</label>
        <select name="destination" id="destination">
            <option value="">-- Select Destination --</option>
            <% for (String station : stationNames) { %>
                <option value="<%= station %>" <%= station.equals(destination) ? "selected" : "" %>><%= station %></option>
            <% } %>
        </select>
        <label for="travelDate">Travel Date:</label>
        <input type="date" name="travelDate" value="<%= travelDate %>">

        <label for="sortBy">Sort By:</label>
        <select name="sortBy" id="sortBy">
            <option value="firstStopTime" <%= "firstStopTime".equals(sortBy) ? "selected" : "" %>>Arrival Time</option>
            <option value="lastStopTime" <%= "lastStopTime".equals(sortBy) ? "selected" : "" %>>Departure Time</option>
            <option value="baseFare" <%= "baseFare".equals(sortBy) ? "selected" : "" %>>Fare</option>
        </select>

        <button type="submit">Filter</button>
    </form>

    <!-- Train Schedule Table -->
    <table border="1">
        <tr>
            <th>Transit Line</th>
            <th>Train Name</th>
            <th>Route</th>
            <th>First Stop Time</th>
            <th>Last Stop Time</th>
            <th>Fare</th>
            <th>Select</th>
        </tr>
        <% boolean hasSchedules = false; %>
        <% while (rs.next()) { %>
            <% 
                String routeStops = rs.getString("routeStops");
                if (routeStops != null && !routeStops.isEmpty()) {
                    String[] stops = routeStops.split(" -> ");
                    if (stops.length > 0) {
                        String firstStop = stops[0];
                        String lastStop = stops[stops.length - 1];

                        if ((origin == null || origin.isEmpty() || origin.equals(firstStop)) &&
                            (destination == null || destination.isEmpty() || destination.equals(lastStop))) {
                                hasSchedules = true;
            %>
            <tr>
                <td><%= rs.getString("transitLine") %></td>
                <td><%= rs.getString("trainName") %></td>
                <td><%= routeStops %></td>
                <td><%= rs.getTimestamp("firstStopTime") %></td>
                <td><%= rs.getTimestamp("lastStopTime") %></td>
                <td><%= rs.getFloat("baseFare") %></td>
                <td>
                    <form action="makeOneWayReservation.jsp" method="post">
                        <input type="hidden" name="selectedSchedule" value="<%= rs.getString("transitLine") + "," + rs.getString("trainName") + "," + routeStops + "," + rs.getTimestamp("firstStopTime") + "," + rs.getTimestamp("lastStopTime") + "," + rs.getFloat("baseFare") + "," + rs.getDate("travelDate") %>">
                        <button type="submit">Make One-Way Reservation</button>
                    </form>
                    <form action="makeTwoWayReservation.jsp" method="post">
                        <input type="hidden" name="selectedSchedule" value="<%= rs.getString("transitLine") + "," + rs.getString("trainName") + "," + routeStops + "," + rs.getTimestamp("firstStopTime") + "," + rs.getTimestamp("lastStopTime") + "," + rs.getFloat("baseFare") + "," + rs.getDate("travelDate") %>">
                        <button type="submit">Make Two-Way Reservation</button>
                    </form>
                </td>
            </tr>
            <% 
                        }
                    }
                } 
            %>
        <% } %>
        <% if (!hasSchedules) { %>
        <tr>
            <td colspan="8">No train schedules available.</td>
        </tr>
        <% } %>
    </table>
    <br>
</body>
</html>
<%
    } catch (Exception e) {
        e.printStackTrace(new PrintWriter(out)); // Exception handling
        out.println("<h3>Error occurred while processing the request.</h3>");
    } finally {
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
%>
