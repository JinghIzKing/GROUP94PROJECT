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
        // Retrieve form parameters
        String route = request.getParameter("route");
        String type = request.getParameter("type");
        String originStop = request.getParameter("originStop");
        String destinationStop = request.getParameter("destinationStop");
        String discountType = request.getParameter("discountType");
        String passenger = request.getParameter("passenger");

        // Fare calculation variables
        double baseFare = 0.0; // Initialize baseFare to 0
        int totalStops = 0;
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

            // Get total stops for the route based on unique stop times
            stmt = conn.prepareStatement("SELECT COUNT(DISTINCT aTime) AS totalStops FROM RouteStops WHERE name = ?");
            stmt.setString(1, route);
            rs = stmt.executeQuery();
            if (rs.next()) {
                totalStops = rs.getInt("totalStops");
            }
            rs.close();
            stmt.close();

            // Get arrival times for origin and destination
            String originTime = null;
            String destinationTime = null;
            stmt = conn.prepareStatement("SELECT aTime FROM RouteStops WHERE name = ? AND sid = ? ORDER BY aTime ASC");
            stmt.setString(1, route);

            // Get origin stop arrival time
            stmt.setString(2, originStop);
            rs = stmt.executeQuery();
            if (rs.next()) {
                originTime = rs.getString("aTime");
            }
            rs.close();

            // Get destination stop arrival time
            stmt.setString(2, destinationStop);
            rs = stmt.executeQuery();
            if (rs.next()) {
                destinationTime = rs.getString("aTime");
            }
            rs.close();
            stmt.close();

            // Calculate fare
            double fare;
            if ("two-way".equals(type)) {
                // Two-way trip: Base fare is twice the baseFare
                fare = 2 * baseFare * discountMultiplier;
            } else {
                // One-way trip: Calculate fare based on stops
                // Determine the earlier and later times for the range
                String startTime = originTime.compareTo(destinationTime) <= 0 ? originTime : destinationTime;
                String endTime = originTime.compareTo(destinationTime) > 0 ? originTime : destinationTime;

                // Calculate stops between (inclusive of origin and destination stops)
                stmt = conn.prepareStatement(
                    "SELECT COUNT(*) AS stopsBetween FROM RouteStops WHERE name = ? AND aTime BETWEEN ? AND ?");
                stmt.setString(1, route);
                stmt.setString(2, startTime);
                stmt.setString(3, endTime);
                rs = stmt.executeQuery();

                int stopsTraveled = 0;
                if (rs.next()) {
                    stopsTraveled = rs.getInt("stopsBetween") - 1; // Exclude starting stop if needed
                }
                rs.close();
                stmt.close();

                // Calculate fare
                fare = (baseFare / (totalStops - 1)) * stopsTraveled * discountMultiplier;
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
