local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local tablePanel = grafana.tablePanel;
local annotation = grafana.annotation;
local singlestat = grafana.singlestat;
local piechart = grafana.pieChartPanel;
local promgrafonnet = import '../lib/promgrafonnet/promgrafonnet.libsonnet';
local numbersinglestat = promgrafonnet.numbersinglestat;
local gauge = promgrafonnet.gauge;

{
  grafanaDashboards+:: {

    'cluster-total.json':

      local newStyle(
        alias,
        colorMode=null,
        colors=[],
        dateFormat='YYYY-MM-DD HH:mm:ss',
        decimals=2,
        link=false,
        linkTooltip='Drill down',
        linkUrl='',
        pattern='',
        thresholds=[],
        type='number',
        unit='short'
            ) = {
        alias: alias,
        colorMode: colorMode,
        colors: colors,
        dateFormat: dateFormat,
        decimals: decimals,
        link: link,
        linkTooltip: linkTooltip,
        linkUrl: linkUrl,
        pattern: pattern,
        thresholds: thresholds,
        type: type,
        unit: unit,
      };

      local newPieChartPanel(pieChartTitle, pieChartQuery) =
        local target =
          prometheus.target(
            pieChartQuery
          ) + {
            instant: null,
            intervalFactor: 1,
            legendFormat: '{{namespace}}',
          };

        piechart.new(
          title=pieChartTitle,
          datasource='prometheus',
          pieType='donut',
        ).addTarget(target) + {
          breakpoint: '50%',
          cacheTimeout: null,
          combine: {
            label: 'Others',
            threshold: 0,
          },
          fontSize: '80%',
          format: 'Bps',
          interval: null,
          legend: {
            percentage: true,
            percentageDecimals: null,
            show: true,
            values: true,
          },
          legendType: 'Right side',
          maxDataPoints: 3,
          nullPointMode: 'connected',
          valueName: 'current',
        };


      local newGraphPanel(graphTitle, graphQuery, graphFormat='Bps') =
        local target =
          prometheus.target(
            graphQuery
          ) + {
            intervalFactor: 1,
            legendFormat: '{{namespace}}',
            step: 10,
          };

        graphPanel.new(
          title=graphTitle,
          span=24,
          datasource='prometheus',
          fill=2,
          linewidth=2,
          min_span=24,
          format=graphFormat,
          min=0,
          max=null,
          x_axis_mode='time',
          x_axis_values='total',
          lines=true,
          stack=true,
          legend_show=true,
          legend_values=true,
          legend_min=true,
          legend_max=true,
          legend_current=true,
          legend_avg=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          nullPointMode='connected'
        ).addTarget(target) + {
          legend+: {
            hideEmpty: true,
            hideZero: true,
          },
          paceLength: 10,
          tooltip+: {
            sort: 2,
          },
        };

      local newTablePanel(tableTitle, colQueries) =
        local buildTarget(index, colQuery) =
          prometheus.target(
            colQuery,
            format='table',
            instant=true,
          ) + {
            legendFormat: '',
            step: 10,
            refId: std.char(65 + index),
          };

        local targets = std.mapWithIndex(buildTarget, colQueries);

        tablePanel.new(
          title=tableTitle,
          span=24,
          min_span=24,
          datasource='prometheus',
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Time',
            type='hidden',
            pattern='Time',
          )
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Current Bandwidth Received',
            pattern='Value #A',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Current Bandwidth Transmitted',
            pattern='Value #B',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Average Bandwidth Received',
            pattern='Value #C',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Average Bandwidth Transmitted',
            pattern='Value #D',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Received Packets',
            pattern='Value #E',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Transmitted Packets',
            pattern='Value #F',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Received Packets Dropped',
            pattern='Value #G',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Transmitted Packets Dropped',
            pattern='Value #H',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Namespace',
            pattern='namespace',
            link=true,
            linkUrl='d/8b7a8b326d7a6f1f04244066368c67af/kubernetes-networking-namespace-pods?orgId=1&refresh=30s&var-namespace=$__cell',
          ),
        ) + {

          fill: 1,
          fontSize: '90%',
          lines: true,
          linewidth: 1,
          nullPointMode: 'null as zero',
          renderer: 'flot',
          scroll: true,
          showHeader: true,
          spaceLength: 10,
          sort: {
            col: 0,
            desc: false,
          },
          targets: targets,
        };

      local resolutionTemplate =
        template.new(
          name='resolution',
          datasource='prometheus',
          query='30s,5m,1h',
          current='5m',
          hide='',
          refresh=2,
          includeAll=false,
          sort=1
        ) + {
          auto: false,
          auto_count: 30,
          auto_min: '10s',
          skipUrlSync: false,
          type: 'interval',
          options: [
            {
              selected: false,
              text: '30s',
              value: '30s',
            },
            {
              selected: true,
              text: '5m',
              value: '5m',
            },
            {
              selected: false,
              text: '1h',
              value: '1h',
            },
          ],
        };

      local intervalTemplate =
        template.new(
          name='interval',
          datasource='prometheus',
          query='4h',
          current='5m',
          hide=2,
          refresh=2,
          includeAll=false,
          sort=1
        ) + {
          auto: false,
          auto_count: 30,
          auto_min: '10s',
          skipUrlSync: false,
          type: 'interval',
          options: [
            {
              selected: true,
              text: '4h',
              value: '4h',
            },
          ],
        };

      //#####  Current Bandwidth Row ######

      local currentBandwidthRow =
        row.new(
          title='Current Bandwidth'
        );

      //#####  Average Bandwidth Row ######

      local averageBandwidthRow =
        row.new(
          title='Average Bandwidth',
          collapse=true,
        );

      //#####  Bandwidth History Row ######
      local bandwidthHistoryRow =
        row.new(
          title='Bandwidth History'
        );

      //##### Packet  Row ######
      // collapsed, so row must include panels
      local packetRow =
        row.new(
          title='Packets',
          collapse=true,
        );

      //##### Error Row ######
      // collapsed, so row must include panels
      local errorRow =
        row.new(
          title='Errors',
          collapse=true,
        );

      dashboard.new(
        title='%(dashboardNamePrefix)sNetworking / Cluster' % $._config.grafanaK8s,
        tags=($._config.grafanaK8s.dashboardTags),
        editable=true,
        schemaVersion=18,
        refresh='30s',
        time_from='now-1h',
        time_to='now',
      )
      .addTemplate(resolutionTemplate)
      .addTemplate(intervalTemplate)
      .addAnnotation(annotation.default)
      .addPanel(
        currentBandwidthRow, gridPos={ h: 1, w: 24, x: 0, y: 0 }
      )
      .addPanel(
        newPieChartPanel(
          pieChartTitle='Current Rate of Bytes Received',
          pieChartQuery='sort_desc(sum(irate(container_network_receive_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
        ),
        gridPos={ h: 9, w: 12, x: 0, y: 1 }
      )
      .addPanel(
        newPieChartPanel(
          pieChartTitle='Current Rate of Bytes Transmitted',
          pieChartQuery='sort_desc(sum(irate(container_network_transmit_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
        ),
        gridPos={ h: 9, w: 12, x: 12, y: 1 }
      )
      .addPanel(
        newTablePanel(
          tableTitle='Current Status',
          colQueries=[
            'sort_desc(sum(irate(container_network_receive_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(sum(irate(container_network_transmit_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(avg(irate(container_network_receive_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(avg(irate(container_network_transmit_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(sum(irate(container_network_receive_packets_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(sum(irate(container_network_transmit_packets_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(sum(irate(container_network_receive_packets_dropped_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            'sort_desc(sum(irate(container_network_transmit_packets_dropped_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
          ]
        ),
        gridPos={ h: 9, w: 24, x: 0, y: 10 }
      )
      .addPanel(
        averageBandwidthRow
        .addPanel(
          newPieChartPanel(
            pieChartTitle='Average Rate of Bytes Received',
            pieChartQuery='sort_desc(avg(irate(container_network_receive_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
          ),
          gridPos={ h: 9, w: 12, x: 0, y: 11 }
        )
        .addPanel(
          newPieChartPanel(
            pieChartTitle='Average Rate of Bytes Transmitted',
            pieChartQuery='sort_desc(avg(irate(container_network_transmit_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
          ),
          gridPos={ h: 9, w: 12, x: 12, y: 11 }
        ),
        gridPos={ h: 1, w: 24, x: 0, y: 10 },
      )
      .addPanel(
        bandwidthHistoryRow, gridPos={ h: 1, w: 24, x: 0, y: 11 }
      )
      .addPanel(
        newGraphPanel(
          graphTitle='Receive Bandwidth',
          graphQuery='sort_desc(sum(irate(container_network_receive_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
        ),
        gridPos={ h: 9, w: 24, x: 0, y: 12 }
      )
      .addPanel(
        newGraphPanel(
          graphTitle='Transmit Bandwidth',
          graphQuery='sort_desc(sum(irate(container_network_transmit_bytes_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
        ),
        gridPos={ h: 9, w: 24, x: 0, y: 21 }
      )
      .addPanel(
        packetRow
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Received Packets',
            graphQuery='sort_desc(sum(irate(container_network_receive_packets_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            graphFormat='pps'
          ),
          gridPos={ h: 9, w: 24, x: 0, y: 31 }
        )
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Transmitted Packets',
            graphQuery='sort_desc(sum(irate(container_network_transmit_packets_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            graphFormat='pps'
          ),
          gridPos={ h: 9, w: 24, x: 0, y: 40 }
        ),
        gridPos={ h: 1, w: 24, x: 0, y: 30 }
      )
      .addPanel(
        errorRow
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Received Packets Dropped',
            graphQuery='sort_desc(sum(irate(container_network_receive_packets_dropped_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            graphFormat='pps'
          ),
          gridPos={ h: 9, w: 24, x: 0, y: 50 }
        )
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Transmitted Packets Dropped',
            graphQuery='sort_desc(sum(irate(container_network_transmit_packets_dropped_total{namespace=~".+"}[$interval:$resolution])) by (namespace))',
            graphFormat='pps'
          ),
          gridPos={ h: 9, w: 24, x: 0, y: 59 }
        ),
        gridPos={ h: 1, w: 24, x: 0, y: 31 }
      ),
  },
}
