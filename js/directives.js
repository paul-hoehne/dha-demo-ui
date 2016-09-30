app.directive('vcePatient', function() {
  return {
    restrict: 'E',
    scope: {
      patient: "=patient"
    },
    templateUrl: '/partials/directives/vce-patient.html'
  };
});

app.directive("vceEncounter", function() {
  return {
    restrict: 'E',
    scope: {
      encounter: "=encounter"
    },
    templateUrl: "/partials/directives/vce-encounter.html"
  }
});

app.directive("vceMatches", function() {
  return {
    restrict: 'E',
    scope: {
      matches: "=matches"
    },
    templateUrl: "/partials/directives/vce-matches.html"
  }
});

app.directive("vceFacet", function() {
  return {
    restrict: 'E',
    templateUrl: '/partials/directives/vce-facet.html'
  }
});

app.directive("vcePatientCard", function() {
  return {
    restrict: 'E',
    scope: {
      patient: "=patient"
    },
    templateUrl: "/partials/directives/vce-patient-card.html"
  }
});