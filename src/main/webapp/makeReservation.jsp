<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<!DOCTYPE html>
<html>
<head>
    <title>Make Reservation</title>
</head>
<body>
    <h1>Reservation Confirmation</h1>
    <%
        String route = request.getParameter("route");
        String type = request.getParameter("type");
        String originStop = request.getParameter("originStop");
        String destinationStop = request.getParameter("destinationStop");
        String discountType = request.getParameter("discountType");
        String passenger = request.getParameter("passenger");

        double baseFare = 0.0;
        double discountMultiplier = 1.0;

        // Set discount multiplier
        switch (discountType) {
            case "child":
                discountMultiplier = 0.75;
                break;
            case "elder":
                discountMultiplier = 0.65;
                break;
            case "disabled":
                discountMultiplier = 0.5;
                break;
        }

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            ApplicationDB db = new ApplicationDB();
            conn = db.getConnection();

            // Get baseFare from TransitLine
            stmt = conn.prepareStatement("SELECT baseFare FROM TransitLine WHERE name = ?");
            stmt.setString(1, route);
            rs = stmt.executeQuery();
            if (rs.next()) {
                baseFare = rs.getDouble("baseFare");
            } else {
                throw new Exception("Base fare not found for route: " + route);
            }
            rs.close();
            stmt.close();

            double fare = 0.0;

            if ("two-way".equals(type)) {
                // Calculate fare for two-way trips
                fare = 2 * baseFare * discountMultiplier;
            } else if ("one-way".equals(type)) {
                // Validate originStop and destinationStop for one-way trips
                if (originStop == null || destinationStop == null) {
                    out.println("<h3>Error: Missing origin or destination for one-way trip. Please fill out the form completely.</h3>");
                    out.println("<a href='customerReservations.jsp'>Back to Reservations</a>");
                    return;
                }

                // Get total stops for the route
                int totalStops = 0;
                stmt = conn.prepareStatement("SELECT COUNT(DISTINCT aTime) AS totalStops FROM RouteStops WHERE name = ?");
                stmt.setString(1, route);
                rs = stmt.executeQuery();
                if (rs.next()) {
                    totalStops = rs.getInt("totalStops");
                }
                rs.close();
                stmt.close();

                // Get stop times
                String originTime = null, destinationTime = null;
                stmt = conn.prepareStatement("SELECT aTime FROM RouteStops WHERE name = ? AND sid = ? ORDER BY aTime ASC");
                stmt.setString(1, route);
                stmt.setString(2, originStop);
                rs = stmt.executeQuery();
                if (rs.next()) {
                    originTime = rs.getString("aTime");
                }
                rs.close();

                stmt.setString(2, destinationStop);
                rs = stmt.executeQuery();
                if (rs.next()) {
                    destinationTime = rs.getString("aTime");
                }
                rs.close();
                stmt.close();

                if (originTime == null || destinationTime == null) {
                    throw new Exception("Could not retrieve stop times for the selected route.");
                }

                // Calculate stops traveled
                String startTime = originTime.compareTo(destinationTime) <= 0 ? originTime : destinationTime;
                String endTime = originTime.compareTo(destinationTime) > 0 ? originTime : destinationTime;

                stmt = conn.prepareStatement("SELECT COUNT(*) AS stopsTraveled FROM RouteStops WHERE name = ? AND aTime BETWEEN ? AND ?");
                stmt.setString(1, route);
                stmt.setString(2, startTime);
                stmt.setString(3, endTime);
                rs = stmt.executeQuery();

                int stopsTraveled = 0;
                if (rs.next()) {
                    stopsTraveled = rs.getInt("stopsTraveled") - 1;
                }
                rs.close();
                stmt.close();

                // Calculate fare
                fare = baseFare * ((double) stopsTraveled / (totalStops - 1)) * discountMultiplier;
            }

            // Insert reservation
            String reservationNumber = UUID.randomUUID().toString().substring(0, 8);
            stmt = conn.prepareStatement("INSERT INTO Reservation (resNumber, date, totalFare, passenger, line) VALUES (?, NOW(), ?, ?, ?)");
            stmt.setString(1, reservationNumber);
            stmt.setDouble(2, fare);
            stmt.setString(3, passenger);
            stmt.setString(4, route);
            stmt.executeUpdate();
            stmt.close();

            out.println("<h3>Reservation Successful!</h3>");
            out.println("<p>Reservation Number: " + reservationNumber + "</p>");
            out.println("<p>Total Fare: $" + String.format("%.2f", fare) + "</p>");
        } catch (Exception e) {
            e.printStackTrace(new PrintWriter(out));
            out.println("<h3>Error occurred while processing the reservation.</h3>");
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
    %>
    <a href="customerReservations.jsp">Back to Reservations</a>
</body>
</html>
