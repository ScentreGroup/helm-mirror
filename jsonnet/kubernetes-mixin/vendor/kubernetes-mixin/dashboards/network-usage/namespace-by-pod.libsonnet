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

    'namespace-by-pod.json':

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

      local newGaugePanel(gaugeTitle, gaugeQuery) =
        local target =
          prometheus.target(
            gaugeQuery,
          ) + {
            instant: null,
            intervalFactor: 1,
          };

        singlestat.new(
          title=gaugeTitle,
          datasource='prometheus',
          format='time_series',
          height=9,
          span=12,
          min_span=12,
          decimals=0,
          valueName='current'
        ).addTarget(target) + {
          timeFrom: null,
          timeShift: null,
          type: 'gauge',
          options: {
            fieldOptions: {
              calcs: [
                'last',
              ],
              defaults: {
                max: 10000000000,  // 10GBs
                min: 0,
                title: '$namespace',
                unit: 'Bps',
              },
              mappings: [],
              override: {},
              thresholds: [
                {
                  color: 'dark-green',
                  index: 0,
                  value: null,  // 0GBs
                },
                {
                  color: 'dark-yellow',
                  index: 1,
                  value: 5000000000,  // 5GBs
                },
                {
                  color: 'dark-red',
                  index: 2,
                  value: 7000000000,  // 7GBs
                },
              ],
              values: false,
            },
          },
        };

      local newGraphPanel(graphTitle, graphQuery, graphFormat='Bps') =
        local target =
          prometheus.target(
            graphQuery
          ) + {
            intervalFactor: 1,
            legendFormat: '{{pod}}',
            step: 10,
          };

        graphPanel.new(
          title=graphTitle,
          span=12,
          datasource='prometheus',
          fill=2,
          linewidth=2,
          min_span=12,
          format=graphFormat,
          min=0,
          max=null,
          x_axis_mode='time',
          x_axis_values='total',
          lines=true,
          stack=true,
          legend_show=true,
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
            alias='Bandwidth Received',
            pattern='Value #A',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Bandwidth Transmitted',
            pattern='Value #B',
            unit='Bps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Received Packets',
            pattern='Value #C',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Transmitted Packets',
            pattern='Value #D',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Received Packets Dropped',
            pattern='Value #E',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Rate of Transmitted Packets Dropped',
            pattern='Value #F',
            unit='pps',
          ),
        )
        .addColumn(
          field='',
          style=newStyle(
            alias='Pod',
            pattern='pod',
            link=true,
            linkUrl='d/7a18067ce943a40ae25454675c19ff5c/kubernetes-networking-pod?orgId=1&refresh=30s&var-namespace=$namespace&var-pod=$__cell'
          ),
        ) + {

          fill: 1,
          fontSize: '100%',
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


      local namespaceTemplate =
        template.new(
          name='namespace',
          datasource='prometheus',
          query='label_values(container_network_receive_packets_total, namespace)',
          allValues='.+',
          current='kube-system',
          hide='',
          refresh=1,
          includeAll=true,
          sort=1
        ) + {
          auto: false,
          auto_count: 30,
          auto_min: '10s',
          definition: 'label_values(container_network_receive_packets_total, namespace)',
          skipUrlSync: false,
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

      //#####  Bandwidth Row ######

      local bandwidthRow =
        row.new(
          title='Bandwidth'
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
        title='%(dashboardNamePrefix)sNetworking / Namespace (Pods)' % $._config.grafanaK8s,
        tags=($._config.grafanaK8s.dashboardTags),
        editable=true,
        schemaVersion=18,
        refresh='30s',
        time_from='now-1h',
        time_to='now',
      )
      .addTemplate(namespaceTemplate)
      .addTemplate(resolutionTemplate)
      .addTemplate(intervalTemplate)
      .addAnnotation(annotation.default)
      .addPanel(currentBandwidthRow, gridPos={ h: 1, w: 24, x: 0, y: 0 })
      .addPanel(
        newGaugePanel(
          gaugeTitle='Current Rate of Bytes Received',
          gaugeQuery='sum(irate(container_network_receive_bytes_total{namespace=~"$namespace"}[$interval:$resolution]))'
        ),
        gridPos={ h: 9, w: 12, x: 0, y: 1 }
      )
      .addPanel(
        newGaugePanel(
          gaugeTitle='Current Rate of Bytes Transmitted',
          gaugeQuery='sum(irate(container_network_transmit_bytes_total{namespace=~"$namespace"}[$interval:$resolution]))'
        ),
        gridPos={ h: 9, w: 12, x: 12, y: 1 }
      )
      .addPanel(
        newTablePanel(
          tableTitle='Current Status',
          colQueries=[
            'sum(irate(container_network_receive_bytes_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            'sum(irate(container_network_transmit_bytes_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            'sum(irate(container_network_receive_packets_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            'sum(irate(container_network_transmit_packets_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            'sum(irate(container_network_receive_packets_dropped_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            'sum(irate(container_network_transmit_packets_dropped_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
          ]
        ),
        gridPos={ h: 9, w: 24, x: 0, y: 10 }
      )
      .addPanel(bandwidthRow, gridPos={ h: 1, w: 24, x: 0, y: 19 })
      .addPanel(
        newGraphPanel(
          graphTitle='Receive Bandwidth',
          graphQuery='sum(irate(container_network_receive_bytes_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)'
        ),
        gridPos={ h: 9, w: 12, x: 0, y: 20 }
      )
      .addPanel(
        newGraphPanel(
          graphTitle='Transmit Bandwidth',
          graphQuery='sum(irate(container_network_transmit_bytes_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)'
        ),
        gridPos={ h: 9, w: 12, x: 12, y: 20 }
      )
      .addPanel(
        packetRow
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Received Packets',
            graphQuery='sum(irate(container_network_receive_packets_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            graphFormat='pps'
          ),
          gridPos={ h: 10, w: 12, x: 0, y: 30 }
        )
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Transmitted Packets',
            graphQuery='sum(irate(container_network_transmit_packets_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            graphFormat='pps'
          ),
          gridPos={ h: 10, w: 12, x: 12, y: 30 }
        ),
        gridPos={ h: 1, w: 24, x: 0, y: 29 }
      )
      .addPanel(
        errorRow
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Received Packets Dropped',
            graphQuery='sum(irate(container_network_receive_packets_dropped_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            graphFormat='pps'
          ),
          gridPos={ h: 10, w: 12, x: 0, y: 40 }
        )
        .addPanel(
          newGraphPanel(
            graphTitle='Rate of Transmitted Packets Dropped',
            graphQuery='sum(irate(container_network_transmit_packets_dropped_total{namespace=~"$namespace"}[$interval:$resolution])) by (pod)',
            graphFormat='pps'
          ),
          gridPos={ h: 10, w: 12, x: 12, y: 40 }
        ),
        gridPos={ h: 1, w: 24, x: 0, y: 30 }
      ),
  },
}
