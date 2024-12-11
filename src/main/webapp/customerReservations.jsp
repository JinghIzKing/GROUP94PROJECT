<%@ page language="java" import="java.sql.*, java.util.UUID" %>
<%@ page import="java.io.*,java.util.*,java.sql.*"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1" import="com.cs336.pkg.*"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="ISO-8859-1">
    <title>Customer Reservations</title>
    <script>
        // JavaScript to filter stops based on the selected route
        function updateStops(transitLine) {
    const originStop = document.getElementById("originStop");
    const destinationStop = document.getElementById("destinationStop");

    // Hide all options initially
    Array.from(originStop.options).forEach(option => {
        option.style.display = "none";
    });
    Array.from(destinationStop.options).forEach(option => {
        option.style.display = "none";
    });

    // Show only options that match the selected route
    let firstOriginOption = null;
    let firstDestinationOption = null;
    Array.from(originStop.options).forEach(option => {
        if (option.dataset.route === transitLine) {
            option.style.display = "block";
            if (!firstOriginOption) firstOriginOption = option;
        }
    });
    Array.from(destinationStop.options).forEach(option => {
        if (option.dataset.route === transitLine) {
            option.style.display = "block";
            if (!firstDestinationOption) firstDestinationOption = option;
        }
    });

    // Reset selections to the first valid option or clear them
    if (firstOriginOption) {
        originStop.value = firstOriginOption.value;
    } else {
        originStop.value = ""; // Clear selection if no options are available
    }

    if (firstDestinationOption) {
        destinationStop.value = firstDestinationOption.value;
    } else {
        destinationStop.value = ""; // Clear selection if no options are available
    }
}


        // Show or hide the stops dropdown based on the trip type
        function toggleStops() {
            const tripType = document.getElementById("type").value;
            const stopSelection = document.getElementById("stopSelection");
            stopSelection.style.display = tripType === "one-way" ? "block" : "none";
        }
    </script>
</head>
<body>
    <h1>Customer Reservation Management</h1>
    
    <!-- Make a Reservation -->
    <h2>Make a Reservation</h2>
    <form method="post" action="makeReservation.jsp">
        <!-- Route Selection -->
        <label for="route">Select Route:</label>
        <select name="route" id="route" required onchange="updateStops(this.value)">
            <option value="">-- Select a Route --</option>
            <%
                ApplicationDB db = new ApplicationDB();
                Connection conn = db.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT name FROM TransitLine");
                while (rs.next()) {
                    out.println("<option value='" + rs.getString("name") + "'>" + rs.getString("name") + "</option>");
                }
                rs.close();
                stmt.close();
            %>
        </select>
        <br>
        
        <!-- Trip Type -->
        <label for="type">Trip Type:</label>
        <select name="type" id="type" onchange="toggleStops()" required>
            <option value="two-way">Two-Way</option>
            <option value="one-way">One-Way</option>
        </select>
        <br>
        
        <!-- Stops Selection -->
        <div id="stopSelection" style="display:none;">
            <label for="originStop">Select Origin Stop:</label>
            <select name="originStop" id="originStop" required>
                <%
                    PreparedStatement stopStmt = conn.prepareStatement(
                        "SELECT rs.sid, rs.name AS routeName, s.name AS stationName " +
                        "FROM RouteStops rs JOIN Station s ON rs.sid = s.sid ORDER BY rs.name, rs.dTime"
                    );
                    ResultSet stopRs = stopStmt.executeQuery();
                    while (stopRs.next()) {
                        String sid = stopRs.getString("sid");
                        String routeName = stopRs.getString("routeName");
                        String stationName = stopRs.getString("stationName");
                        out.println("<option value='" + sid + "' data-route='" + routeName + "' style='display:none;'>" + stationName + "</option>");
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
                        "SELECT rs.sid, rs.name AS routeName, s.name AS stationName " +
                        "FROM RouteStops rs JOIN Station s ON rs.sid = s.sid ORDER BY rs.name, rs.dTime"
                    );
                    stopRs = stopStmt.executeQuery();
                    while (stopRs.next()) {
                        String sid = stopRs.getString("sid");
                        String routeName = stopRs.getString("routeName");
                        String stationName = stopRs.getString("stationName");
                        out.println("<option value='" + sid + "' data-route='" + routeName + "' style='display:none;'>" + stationName + "</option>");
                    }
                    stopRs.close();
                    stopStmt.close();
                %>
            </select>
            <br>
        </div>
        
        <!-- Discount Type -->
        <label for="discountType">Passenger Type (Discount):</label>
        <select name="discountType" id="discountType" required>
            <option value="none">None</option>
            <option value="child">Child (25% Off)</option>
            <option value="elder">Elder (35% Off)</option>
            <option value="disabled">Disabled (50% Off)</option>
        </select>
        <br>
        
        <!-- Passenger Name -->
        <label for="passenger">Passenger Name:</label>
        <input type="text" name="passenger" id="passenger" required>
        <br>

        <input type="submit" value="Make Reservation">
    </form>
</body>

    <!-- View Reservations -->
    <h2>View Reservations</h2>
    <form method="get" action="viewReservations.jsp">
        <label for="username">Enter Username:</label>
        <input type="text" name="username" id="username" required>
        <br>
        <input type="submit" value="View Reservations">
    </form>
</body>
</html>
