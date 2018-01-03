/* global Vue */
document.addEventListener("DOMContentLoaded", function(event) { 
  var app = new Vue({
    el: '#app',
    data() {
      return {
        leads: [],
        time_format: "12/25/17",
        url: "https://www.google.com/",
        search: '',
        reverse: 1
      };
    },
    mounted: function() {
      $.get('/api/v1/leads.json').success(function(response) {
        console.log(this);
        this.leads = response;
        this.leads = _.map(this.leads, function(lead){
          lead.events = _.orderBy(lead.events, 'created_at', 'desc');
          return lead;
        })
        this.leads = _.orderBy(this.leads, 'events[0].created_at', 'desc');
      }.bind(this));
    },
    methods: {
      moment: function(date) {
        return moment(date);
      },
      sortAscDec: function(col) {
        if (this.reverse === 1) {
          this.leads = _.orderBy(this.leads, col);
          this.reverse *= -1;
        } else {
          this.leads = _.orderBy(this.leads, col, 'desc');
          this.reverse *= -1;
        }
      },
      showEvents: function(lead) {
        //creates a string with a lead id.
        if (!lead) { return; }
        var $eventRow = $("#" + lead.id + "-events");  
        if ($eventRow.length === 0) { 
          var eventsString = "";
          for (event of lead.events) {
            eventsString += '<div class="row">';
            eventsString += '<div class="col-md-2">' + event.name + '</div>';
            eventsString += '<div class="col-md-4">' + this.moment(event.created_at).format('dddd MMM Do YYYY, h:mm a') + '</div>';
            // this loop double checks whether or not the event exists already, if it doesn't it will create a string into the html.
            eventsString += '</div>';
          };                                  // this loop double checks whether or not the event exists already, if it doesn't it will create a string into the html.
          var $row = $('#lead-' + lead.id);
          if (lead.events.length === 0) {
            var idString = '' + lead.id + '-events';
            var $newRow = $('<tr id=' + idString + '><td colspan="7">EVENTS: No Events</td></tr>');
          } else {
            var idString = '' + lead.id + '-events';
            var $newRow = $('<tr id=' + idString + ' class="event-row"><td colspan="7">' +
              // no events == no events 
              eventsString + "</td></tr>");
          };                
          $row.after($newRow);
        } else {
          // if events row exists then remove tho row(toggle).
          $eventRow.remove();  
        }
      }, 
      rowColor: function(lead){
        
        if (!lead.outreaches.length){
          return 'background-color:orange';
        }

        var latestEventDate = _
          .chain(lead.events)
          .orderBy('updated_at', ['desc'])
          .head()
          .value()
          .updated_at;

        var latestOutreachDate = _
          .chain(lead.outreaches)
          .orderBy('updated_at', ['desc'])
          .head()
          .value()
          .updated_at;

        if (latestEventDate > latestOutreachDate) {
          return 'background-color:#0cc6f4;';
        } else {
          return '';
        }
      }
    },
    computed: {
      filteredLeads: function() {
        //removing any additional event 
        $('.event-row').remove(); 
        var search = this.search.toLowerCase();
        return this.leads.filter(
          function(lead){
            return lead.first_name.toLowerCase().includes(search) ||
              lead.last_name.toLowerCase().includes(search) ||
              lead.email.toLowerCase().includes(search);
            }
          );
        }
    }

  });
})
