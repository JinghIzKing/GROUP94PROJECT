<%@ page import="java.io.*,java.util.*,java.sql.*,java.util.UUID" %>
<%@ page import="javax.servlet.http.*,javax.servlet.*" %>
<%@ page import="com.cs336.pkg.ApplicationDB" %>
<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page session="true" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) {
        username = "placeholder";
    }

    String selectedSchedule = request.getParameter("selectedSchedule");
    if (selectedSchedule == null || selectedSchedule.isEmpty()) {
        out.println("<h3>Error: Missing schedule data. Please go back and select a schedule.</h3>");
        return;
    }

    String[] scheduleDetails = selectedSchedule.split(",");
    if (scheduleDetails.length < 7) {
        out.println("<h3>Error: Incomplete schedule data. Please try again.</h3>");
        return;
    }

    // Extract details from the selected schedule
    String transitLine = scheduleDetails[0];
    String trainName = scheduleDetails[1];
    String routeStops = scheduleDetails[2];
    String firstStopTime = scheduleDetails[3];
    String lastStopTime = scheduleDetails[4];
    float baseFare = Float.parseFloat(scheduleDetails[5]);
    String travelDate = scheduleDetails[6];

    // Passenger and discount information
    String passengerName = request.getParameter("passengerName");
    String boardingStation = request.getParameter("boardingStation");
    String alightingStation = request.getParameter("alightingStation");
    String discountType = request.getParameter("discountType");
    String confirmation = request.getParameter("confirmReservation");

    float discountPercentage = 0.0f;
    float finalFare = baseFare;

    // Apply discount logic
    if (discountType != null && !discountType.isEmpty()) {
        switch (discountType) {
            case "child":
                discountPercentage = 0.25f; // 25% discount
                break;
            case "elder":
                discountPercentage = 0.35f; // 35% discount
                break;
            case "disabled":
                discountPercentage = 0.50f; // 50% discount
                break;
            case "adult":
                discountPercentage = 0.0f; // No discount for adults
                break;
        }
    }

    int boardingIndex = -1;
    int alightingIndex = -1;

    // Validate and calculate travel fraction
    if (boardingStation != null && alightingStation != null) {
        String[] stops = routeStops.split(" -> ");
        for (int i = 0; i < stops.length; i++) {
            if (stops[i].equals(boardingStation)) boardingIndex = i;
            if (stops[i].equals(alightingStation)) alightingIndex = i;
        }

        if (boardingIndex < 0 || alightingIndex < 0 || boardingIndex >= alightingIndex) {
            out.println("<h3>Error: Invalid boarding and alighting stations. Please try again.</h3>");
            return;
        }

        // Calculate fare based on travel fraction
        int travelStops = alightingIndex - boardingIndex;
        int totalStops = stops.length - 1;
        finalFare = baseFare * ((float) travelStops / totalStops) * (1 - discountPercentage);
    }

    if ("true".equals(confirmation)) {
        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            ApplicationDB db = new ApplicationDB();
            conn = db.getConnection();

            // Fetch `tid` based on `trainName`
            String fetchTidQuery = "SELECT tid FROM train WHERE tName = ?";
            stmt = conn.prepareStatement(fetchTidQuery);
            stmt.setString(1, trainName);
            ResultSet tidResult = stmt.executeQuery();

            int tid = -1;
            if (tidResult.next()) {
                tid = tidResult.getInt("tid");
            }
            tidResult.close();
            stmt.close();

            if (tid == -1) {
                out.println("<h3>Error: Unable to fetch train ID (tid). Please try again later.</h3>");
                return;
            }

            // Generate unique reservation number
            String resNumber;
            boolean isUnique = false;
            do {
                resNumber = UUID.randomUUID().toString().substring(0, 8);
                String checkQuery = "SELECT COUNT(*) FROM reservation WHERE resNumber = ?";
                PreparedStatement checkStmt = conn.prepareStatement(checkQuery);
                checkStmt.setString(1, resNumber);
                ResultSet rsCheck = checkStmt.executeQuery();
                if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                    isUnique = true;
                }
                rsCheck.close();
                checkStmt.close();
            } while (!isUnique);

            // Insert reservation into database
            String insertQuery = """
                INSERT INTO reservation (username, resNumber, date, totalFare, passenger, line, sidStart, sidStop, discountType, tid, aTime, dTime, tripType)
                VALUES (?, ?, CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;

            stmt = conn.prepareStatement(insertQuery);
            stmt.setString(1, username); // Username
            stmt.setString(2, resNumber); // Reservation number
            stmt.setFloat(3, finalFare); // Total fare
            stmt.setString(4, passengerName); // Passenger name
            stmt.setString(5, transitLine); // Line (train line name)
            stmt.setInt(6, boardingIndex + 1); // sidStart (adjusted for DB index)
            stmt.setInt(7, alightingIndex + 1); // sidStop (adjusted for DB index)
            stmt.setString(8, discountType); // Discount type
            stmt.setInt(9, tid); // Train ID
            stmt.setString(10, firstStopTime); // aTime
            stmt.setString(11, lastStopTime); // dTime
            stmt.setString(12, "one-way"); // tripType

            stmt.executeUpdate();

            out.println("<h3>Reservation confirmed! Your reservation number is: " + resNumber + "</h3>");
            out.println("<a href='viewReservations.jsp'>View Reservations</a>");
        } catch (Exception e) {
            e.printStackTrace(new PrintWriter(out));
            out.println("<h3>Error: Unable to save reservation. Please try again later.</h3>");
        } finally {
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>One-Way Reservation</title>
</head>
<body>
    <h1>One-Way Reservation</h1>
    <h3>Review Your Selected Schedule</h3>
    <table border="1">
        <tr>
            <th>Transit Line</th>
            <td><%= transitLine %></td>
        </tr>
        <tr>
            <th>Train Name</th>
            <td><%= trainName %></td>
        </tr>
        <tr>
            <th>Route</th>
            <td><%= routeStops %></td>
        </tr>
        <tr>
            <th>Base Fare</th>
            <td>$<%= String.format("%.2f", baseFare) %></td>
        </tr>
        <tr>
            <th>Travel Date</th>
            <td><%= travelDate %></td>
        </tr>
    </table>

    <h3>Enter Passenger Information</h3>
    <form action="makeOneWayReservation.jsp" method="post">
        <input type="hidden" name="selectedSchedule" value="<%= selectedSchedule %>">
        <label for="passengerName">Passenger Name:</label>
        <input type="text" name="passengerName" id="passengerName" required>
        <br><br>

        <label for="boardingStation">Boarding Station:</label>
        <select name="boardingStation" id="boardingStation" required>
            <% for (String stop : routeStops.split(" -> ")) { %>
                <option value="<%= stop %>"><%= stop %></option>
            <% } %>
        </select>
        <br><br>

        <label for="alightingStation">Alighting Station:</label>
        <select name="alightingStation" id="alightingStation" required>
            <% for (String stop : routeStops.split(" -> ")) { %>
                <option value="<%= stop %>"><%= stop %></option>
            <% } %>
        </select>
        <br><br>

        <h3>Choose a Discount Option</h3>
        <label for="discountType">Discount:</label>
        <select name="discountType" id="discountType" required>
            <option value="">-- Select Discount --</option>
            <option value="adult" <%= "adult".equals(discountType) ? "selected" : "" %>>Adult (No Discount)</option>
            <option value="child" <%= "child".equals(discountType) ? "selected" : "" %>>Child (25% off)</option>
            <option value="elder" <%= "elder".equals(discountType) ? "selected" : "" %>>Elder (35% off)</option>
            <option value="disabled" <%= "disabled".equals(discountType) ? "selected" : "" %>>Disabled (50% off)</option>
        </select>
        <br><br>

        <input type="hidden" name="confirmReservation" value="true">
        <button type="submit">Confirm Reservation</button>
    </form>
</body>
</html>
