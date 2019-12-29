<?xml version="1.0" encoding="UTF-8" ?>
<%--
Copyright (c) 2012-2018, Andy Janata
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions
  and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of
  conditions and the following disclaimer in the documentation and/or other materials provided
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--%>
<%--
Administration tools.

@author Andy Janata (ajanata@socialgamer.net)
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.google.inject.Injector" %>
<%@ page import="com.google.inject.Key" %>
<%@ page import="com.google.inject.TypeLiteral" %>
<%@ page import="net.socialgamer.cah.CahModule.Admins" %>
<%@ page import="net.socialgamer.cah.CahModule.BanList" %>
<%@ page import="net.socialgamer.cah.Constants.DisconnectReason" %>
<%@ page import="net.socialgamer.cah.Constants.LongPollEvent" %>
<%@ page import="net.socialgamer.cah.Constants.LongPollResponse" %>
<%@ page import="net.socialgamer.cah.Constants.ReturnableData" %>
<%@ page import="net.socialgamer.cah.RequestWrapper" %>
<%@ page import="net.socialgamer.cah.StartupUtils" %>
<%@ page import="net.socialgamer.cah.data.ConnectedUsers" %>
<%@ page import="net.socialgamer.cah.data.QueuedMessage" %>
<%@ page import="net.socialgamer.cah.data.QueuedMessage.MessageType" %>
<%@ page import="net.socialgamer.cah.data.User" %>
<%@ page import="java.util.*" %>

<%
RequestWrapper wrapper = new RequestWrapper(request);
ServletContext servletContext = pageContext.getServletContext();
Injector injector = (Injector) servletContext.getAttribute(StartupUtils.INJECTOR);
Set<String> admins = injector.getInstance(Key.get(new TypeLiteral<Set<String>>(){}, Admins.class));
if (!admins.contains(wrapper.getRemoteAddr())) {
  response.sendError(403, "Access is restricted to known hosts");
  return;
}

ConnectedUsers connectedUsers = injector.getInstance(ConnectedUsers.class);
Set<String> banList = injector.getInstance(Key.get(new TypeLiteral<Set<String>>(){}, BanList.class));

// process verbose toggle
String verboseParam = request.getParameter("verbose");
if (verboseParam != null) {
  if (verboseParam.equals("on")) {
    servletContext.setAttribute(StartupUtils.VERBOSE_DEBUG, Boolean.TRUE);
  } else {
    servletContext.setAttribute(StartupUtils.VERBOSE_DEBUG, Boolean.FALSE);
  }
  response.sendRedirect("admin.jsp");
  return;
}

// process kick
String kickParam = request.getParameter("kick");
if (kickParam != null) {
  User user = connectedUsers.getUser(kickParam);
  if (user != null) {
    Map<ReturnableData, Object> data = new HashMap<ReturnableData, Object>();
    data.put(LongPollResponse.EVENT, LongPollEvent.KICKED.toString());
    QueuedMessage qm = new QueuedMessage(MessageType.KICKED, data);
    user.enqueueMessage(qm);

    connectedUsers.removeUser(user, DisconnectReason.KICKED);
  }
  response.sendRedirect("admin.jsp");
  return;
}

// process ban
String banParam = request.getParameter("ban");
if (banParam != null) {
  User user = connectedUsers.getUser(banParam);
  if (user != null) {
   Map<ReturnableData, Object> data = new HashMap<ReturnableData, Object>();
   data.put(LongPollResponse.EVENT, LongPollEvent.BANNED.toString());
   QueuedMessage qm = new QueuedMessage(MessageType.KICKED, data);
   user.enqueueMessage(qm);

   connectedUsers.removeUser(user, DisconnectReason.BANNED);
   banList.add(user.getHostname());
  }
  response.sendRedirect("admin.jsp");
  return;
}

// process unban
String unbanParam = request.getParameter("unban");
if (unbanParam != null) {
  banList.remove(unbanParam);
  response.sendRedirect("admin.jsp");
  return;
}

String reloadLog4j = request.getParameter("reloadLog4j");
if ("true".equals(reloadLog4j)) {
  StartupUtils.reconfigureLogging(this.getServletContext());
}

String reloadProps = request.getParameter("reloadProps");
if ("true".equals(reloadProps)) {
  StartupUtils.reloadProperties(this.getServletContext());
}

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <title>PYX - Admin</title>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"
        integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
</head>
<body>

<div class="container-fluid">
  <div class="row">
    <div class="col">
      <h1>Pretend You're Xyzzy - Admin</h1>
    </div>
  </div>
  <div class="row">
    <div class="col-sm-12 col-md-6">
      <h2>Server Statistics</h2>
    </div>
    <div class="col-sm-12 col-md-6">
      <h2>User Management</h2>
    </div>
  </div>
  <div class="row">
    <div class="col-sm-12 col-md-6">
      <table class="table">
        <thead class="thead-dark">
        <tr>
          <th>Stat</th>
          <th>MiB</th>
        </tr>
        </thead>
        <tr>
          <td>In Use</td>
          <td><%= (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory())
                  / 1024L / 1024L %>
          </td>
        </tr>
        <tr>
          <td>Free</td>
          <td><% out.print(Runtime.getRuntime().freeMemory() / 1024L / 1024L); %></td>
        </tr>
        <tr>
          <td>JVM Allocated</td>
          <td><% out.print(Runtime.getRuntime().totalMemory() / 1024L / 1024L); %></td>
        </tr>
        <tr>
          <td>JVM Max</td>
          <td><% out.print(Runtime.getRuntime().maxMemory() / 1024L / 1024L); %></td>
        </tr>
      </table>
      <p><b>Server up since:</b> <%
        Date startedDate = (Date) servletContext.getAttribute(StartupUtils.DATE_NAME);
        long uptime = System.currentTimeMillis() - startedDate.getTime();
        uptime /= 1000L;
        long seconds = uptime % 60L;
        long minutes = (uptime / 60L) % 60L;
        long hours = (uptime / 60L / 60L) % 24L;
        long days = (uptime / 60L / 60L / 24L);
        out.print(String.format("%s (%d days, %02d:%02d:%02d)",
                startedDate.toString(), days, hours, minutes, seconds));
      %>
      </p>
    </div>
    <div class="col-md-6 col-sm-12">
      <h3>Ban List</h3>
      <table class="table">
        <thead class="thead-dark">
        <tr>
          <th>Host</th>
          <th>Actions</th>
        </tr>
        </thead>
        <tbody>
        <%for (String host : banList) {%>
        <tr>
          <td><%= host %>
          </td>
          <td><a href="?unban=<%= host %>" class="btn btn-info btn-sm" role="button">Un-ban</a></td>
        </tr>
        <%}%>
        </tbody>
      </table>
      <br/>
      <h3>User list:</h3>
      <table class="table">
        <thead class="thead-dark">
        <tr>
          <th>Username</th>
          <th>Host</th>
          <th>Actions</th>
        </tr>
        </thead>
        <tbody>
        <%
          Collection<User> users = connectedUsers.getUsers();
          for (User u : users) {
            // TODO have a ban system. would need to store them somewhere.
        %>
        <tr>
          <td><%= u.getNickname() %>
          </td>
          <td><%= u.getHostname() %>
          </td>
          <td>
            <a href="?kick=<%= u.getNickname() %>" class="btn btn-warning btn-sm" role="button">Kick</a>
            <a href="?ban=<%= u.getNickname() %>" class="btn btn-danger btn-sm" role="button">Ban</a>
          </td>
        </tr>
        <%}%>
        </tbody>
      </table>
    </div>
  </div>
  <div class="row">
    <div class="col">
      <h2>Server Options</h2>
      <%
        // TODO remove this "verbose logging" crap now that log4j is working.
        Boolean verboseDebugObj = (Boolean) servletContext.getAttribute(StartupUtils.VERBOSE_DEBUG);
        boolean verboseDebug = verboseDebugObj != null ? verboseDebugObj.booleanValue() : false;
      %>
      <p>
        <span>Verbose logging is currently <strong><%= verboseDebug ? "ON" : "OFF" %></strong>.</span>
        <div class="btn-group" role="group" aria-label="Basic example">
          <a href="?verbose=on" role="button" class="btn btn-success btn-sm">On</a>
          <a href="?verbose=off" role="button" class="btn btn-danger btn-sm">Off</a>
        </div>
      </p>
      <p><a href="?reloadLog4j=true" class="btn btn-dark" role="button">Reload log4j.properties.</a></p>
      <p><a href="?reloadProps=true" class="btn btn-dark" role="button">Reload pyx.properties.</a></p>
    </div>
  </div>
</div>
<script src="https://code.jquery.com/jquery-3.4.1.slim.min.js"
        integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n"
        crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"
        integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo"
        crossorigin="anonymous"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js"
        integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6"
        crossorigin="anonymous"></script>
</body>
</html>
