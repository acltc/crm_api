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
        reverse: 1,
        sort: 'recent_event_date',
        page: 1
      };
    },
    watch: {
      search: function(val, oldVal) {
        this.filter(val);
      }
    },
    mounted: function() {
      $.get('/api/v1/leads.json').success(function(response) {
        console.log(this);
        this.leads = response;
      }.bind(this));
    },
    methods: {
      moment: function(date) {
        return moment(date);
      },
      sortAscDec: function(col) {
        $('.event-row').remove(); 
        var direction = this.reverse === -1 ? 'ASC' : 'DESC';
        this.reverse *= -1;
        this.sort = col;
        this.page = 1;
        $.get('/api/v1/leads.json?sort=' + col + '&direction=' + direction).success(function(response) {
          this.leads = response;
        }.bind(this));
      },
      filter: function() {
        $('.event-row').remove(); 
        var search = this.search.toLowerCase();
        var direction = this.reverse === 1 ? 'ASC' : 'DESC';
        $.get('/api/v1/leads.json?search=' + search + '&sort=' + this.sort + '&direction=' + direction).success(function(response) {
          this.leads = response;
        }.bind(this));
      },
      showEvents: function(leadId) {
        var $row = $('#events-' + leadId);
        if ($row.is(':visible')) {
          $row.hide();
          return;
        }
        var that = this;
        $.get('/api/v1/leads/' + leadId + '.json').success(function(response){
          var autotext = '<input type="submit" value="Send Auto-Text" id="text-' + response.id + '" class="btn btn-info" style="margin-top 15px; margin-left: auto;">';
          var events = response.events.map(function(event) {
            return '<div class="row" style="margin:0;"><div class="col-md-6">' + event.name + '</div><div class="col-md-6">' + this.moment(event.created_at).format('dddd MMM Do YYYY, h:mm a') + '</div></div>';
          });
          $row.empty();
          if (events.length){
            $row.append('<td class="event-row" colspan="5">' + events.join('') + '</td><td class="event-row" colspan="2">' + autotext + ' </td>');
          } else {
            $row.append('<td class="event-row" colspan="7"><span>No Event History</span></td>');
          }
          $row.fadeIn();
          $('#text-' + leadId).on('click', function(){
            that.autoTextButton(leadId);
          });
        });
      },

      autoTextButton: function(leadId){
        $.post('/auto_text/' + leadId + '.json')
          .success(function(response) {
            if (response.status == 200){
              $('#text-' + leadId).val('Text Sent!');
            } else {
              $('#text-' + leadId).val('Text Failed!');
            }
          });
      },

      rowColor: function(lead){
        if (!lead.outreaches.length){
          return 'background-color:#f7c204';
        }
        var latestEventDate = lead.recent_event_date;
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
      },
      moreLeads: function() {
        var search = this.search.toLowerCase();
        var direction = this.reverse === 1 ? 'ASC' : 'DESC';
        $.get('/api/v1/leads.json?page=' + this.page + '&search=' + search + '&sort=' + this.sort + '&direction=' + direction).success(function(response) {
          console.log(this);
          this.leads = _.concat(this.leads, response);
          this.page++;
        }.bind(this));
      }
    }

  });
})
