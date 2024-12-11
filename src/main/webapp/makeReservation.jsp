<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="javax.servlet.http.*,javax.servlet.*"%>
<!DOCTYPE html>
<html>
<head>
    <title>Make Reservation</title>
</head>
<body>
    <h1>Reservation Confirmation</h1>
    <%
        // Retrieve form parameters
        String route = request.getParameter("route");
        String type = request.getParameter("type");
        String originStop = request.getParameter("originStop");
        String destinationStop = request.getParameter("destinationStop");
        String discountType = request.getParameter("discountType");
        String passenger = request.getParameter("passenger");

        // Fare calculation variables
        double baseFare = 50.0;
        int totalStops = 0;
        int originOrder = 0;
        int destinationOrder = 0;
        double discountMultiplier = 1.0;

        // Set discount multiplier based on passenger type
        if ("child".equals(discountType)) {
            discountMultiplier = 0.75;
        } else if ("elder".equals(discountType)) {
            discountMultiplier = 0.6;
        } else if ("disabled".equals(discountType)) {
            discountMultiplier = 0.5;
        }

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            // Connect to the database
            ApplicationDB db = new ApplicationDB();
            conn = db.getConnection();

            // Get total stops for the route
            stmt = conn.prepareStatement("SELECT COUNT(*) FROM RouteStops WHERE name = ?");
            stmt.setString(1, route);
            rs = stmt.executeQuery();
            if (rs.next()) {
                totalStops = rs.getInt(1);
            }
            rs.close();
            stmt.close();

            // Get stop orders for origin and destination
            stmt = conn.prepareStatement("SELECT stopOrder FROM RouteStops WHERE name = ? AND sid = ?");
            stmt.setString(1, route);
            stmt.setString(2, originStop);
            rs = stmt.executeQuery();
            if (rs.next()) {
                originOrder = rs.getInt("stopOrder");
            }
            rs.close();
            stmt.setString(2, destinationStop);
            rs = stmt.executeQuery();
            if (rs.next()) {
                destinationOrder = rs.getInt("stopOrder");
            }
            rs.close();
            stmt.close();

            // Calculate fare
            double fare;
            if ("two-way".equals(type)) {
                // Two-way trip: Base fare is $100
                fare = 100.0 * discountMultiplier;
            } else {
                // One-way trip: Calculate fare based on stops
                int stopDiff = Math.abs(destinationOrder - originOrder);
                fare = (baseFare / (totalStops - 1)) * stopDiff * discountMultiplier;
            }

            // Insert reservation into the database
            String reservationNumber = UUID.randomUUID().toString().substring(0, 8);
            stmt = conn.prepareStatement("INSERT INTO Reservation (resNumber, date, totalFare, passenger) VALUES (?, NOW(), ?, ?)");
            stmt.setString(1, reservationNumber);
            stmt.setDouble(2, fare);
            stmt.setString(3, passenger);
            stmt.executeUpdate();
            stmt.close();

            // Display success message
            out.println("<h3>Reservation Successful!</h3>");
            out.println("<p>Reservation Number: " + reservationNumber + "</p>");
            out.println("<p>Total Fare: $" + String.format("%.2f", fare) + "</p>");
        } catch (Exception e) {
        	e.printStackTrace(new PrintWriter(out)); // Use PrintWriter for stack trace
            out.println("<h3>Error occurred while applying the discount.</h3>");
        } finally {
            // Close resources
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
    %>
    <a href="customerReservations.jsp">Back to Reservations</a>
</body>
</html>
