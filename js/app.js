app = angular.module("app", ["ui.router", "ui.bootstrap"]);

app.config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {
  $urlRouterProvider.otherwise('/home');

  $stateProvider.state('home', {
    url: '/home',
    templateUrl: '/partials/home.html',
    controller: 'searchCtrl'
  });

  $stateProvider.state('patient', {
    url: '/patient/:id',
    templateUrl: '/partials/patient.html',
    controller: 'patientCtrl'
  })
}]);

app.factory('searchSrvc', ['$http', function($http) {
  return {
    search: function($parameters) {
      var searchString = "/services/search.xqy";
      var queryParts = [];
      var queryText = "";

      if ($parameters.qtext) {
        queryText = $parameters.qtext;
      }

      var faceting = [];
      angular.forEach($parameters.facets, function(value, key) {
        var options = value;
        var facetName = key;

        var selectedValues = [];
        angular.forEach(options, function(temp, valueName) {
          selectedValues.push(key + ':"' + valueName + '"');
        });

        if (selectedValues.length > 0) {
          faceting.push("(" + selectedValues.join(" OR ") + ")");
        }
      });

      if (faceting.length > 0) {
        if (queryText != "") {
          queryText += " ";
        }
        queryText += faceting.join(" AND ");
      }

      queryParts.push("qtext=" + queryText);

      if ($parameters.start) {
        queryParts.push('start=' + $parameters.start);
      }

      var formattedQueryString = queryParts.join("&");
      if (formattedQueryString != "") {
        searchString += ("?" + formattedQueryString);
      }


      return $http.get(searchString);
    }
  }
}]);

app.factory('detailsSrvc', ['$http', function($http) {
  return {
    details: function($uri) {
      return $http.get('/services/details.xqy?uri=' + $uri)
    }, 
    baseballCard: function($id) {
      return $http.get('/services/baseball-card.xqy?patient-id=' + $id)
    }
  };
}]);




app.controller('searchCtrl', ['$scope', 'searchSrvc', 'detailsSrvc', function($scope, searchSrvc, detailsSrvc) {
  $scope.searchParameters = {
    qtext: "",
    facets: {}
  };

  $scope.search = function() {
    searchSrvc.search($scope.searchParameters).then(function(result) {
      $scope.data = result.data;
    }, function(error) {
      $scope.error = {
        message: "unable to retreive data"
      }
    });
  };

  $scope.pageChanged = function() {
    $scope.searchParameters.start = ($scope.searchParameters.currentPage - 1) * $scope.data.pageLength + 1;
    $scope.search();
  };

  $scope.toggleFacet = function(facetName, valueName) {
    if (!$scope.searchParameters.facets[facetName]) {
      $scope.searchParameters.facets[facetName] = {};
    }

    if (!$scope.searchParameters.facets[facetName][valueName]) {
      $scope.searchParameters.facets[facetName][valueName] = true;
    } else {
      delete $scope.searchParameters.facets[facetName][valueName];
    }

    $scope.search();
  };

  $scope.selectObject = function(uri) {
    delete $scope.details;
    delete $scope.patientCard;
    detailsSrvc.details(uri).then(function(result) {
      $scope.details = result.data;
    }, function(error) {
      $scope.error = {
        message: "Unable to retrieve details"
      }
    });
  };

  $scope.baseballCard = function(id) {
    delete $scope.patientCard;
    delete $scope.details;
    detailsSrvc.baseballCard(id).then(function(result) {
      $scope.patientCard = result.data;
    }, function(error) {
      $scope.error = {
        message: "Failed to get baseball card"
      }
    });
  };

  $scope.clear = function() {
    $scope.searchParameters.qtext = "";
    $scope.searchParameters.facets = {};
    $scope.searchParameters.start = 1;
    $scope.searchParameters.currentPage = 1;
    $scope.search();
  };

  $scope.search();

}]);

app.filter('uncamel', function() {
  return function(input) {
    return input.replace(/([A-Z])/g, ' $1').replace(/^./, function(str){ return str.toUpperCase(); })
  }
});
