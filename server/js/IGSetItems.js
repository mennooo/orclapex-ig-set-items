/* global apex $ */
window.mho = window.mho || {}
;(function (namespace) {
  let gColumnBindings = []

  // Support for multiple ways to show multiselection on page items
  let gMultiSelectionMethods = {
    label: {
      onTrue: function (itemName) {
        let label$ = $('label[for="' + itemName + '"]')
        label$.find('.multi-marker').remove()
        label$.prepend('<span class="fa fa-layers multi-marker u-hot-text" aria-hidden="true"></span> ')
      },
      onFalse: function (itemName) {
        let label$ = $('label[for="' + itemName + '"]')
        label$.find('.multi-marker').remove()
      }
    }
  }

  /*
    Region widgets may not exist on page load.
    So we will create a promise and return the widget element on creation
  */
  function _getWidget (regionId) {
    let region = apex.region(regionId)
    let ig$ = region.widget()
    let deferred = $.Deferred()

    if (ig$.length > 0) {
      deferred.resolve(ig$)
    } else {
      region.element.on('interactivegridcreate', function () {
        deferred.resolve(region.widget())
      })
    }

    return deferred.promise()
  }

  function _getModel (grid$) {
    return apex.model.get(grid$.grid('option', 'modelName'))
  }

  function _stringToArray (value) {
    if (value.length === 0) {
      return []
    } else {
      return value.split(',')
    }
  }

  function _allEqual (arr) {
    return arr.every(function (item) {
      return item === arr[0]
    })
  }

  function _getPrimaryKeyColumns (grid$) {
    let columns = grid$.grid('getColumns')
    let model = _getModel(grid$)
    return columns
      .filter(function (column) {
        return model.isIdentityField(column.property)
      })
      .map(function (column) {
        return column.property
      })
  }

  /**
   * Function is copied from apex.model
   * If a record is identified by a surrogate PK, it should return an array.
   * If not, it should return a string
   *
   * @param {any} recordIdentity
   * @returns Array or String as record index value
   */
  function _makeIdentityIndex (recordIdentity) {
    if (typeof recordIdentity === 'string') {
      return recordIdentity
    } else if ($.isArray(recordIdentity)) {
      if (recordIdentity.length === 1) {
        return '' + recordIdentity[0]
      }
      return JSON.stringify(recordIdentity)
    }
    // really shouldn't get here
    return recordIdentity.toString()
  }

  /**
   * This function tries to select a record in the IG
   *
   * @param {any} grid$ jQuery selector of grid element
   * @param {any} indentityIndex Array or value of record ID (primary key)
   * @param {any} replace If there is an active selection in the grid, should it be replaced?
   */
  function _selectRecord (grid$, indentityIndex, replace) {
    // Get current selection
    let selectedRecords = grid$.grid('getSelectedRecords')
    let model = _getModel(grid$)

    // Keep existing selection?
    if (selectedRecords.length > 0) {
      if (!replace) {
        return
      }
    }

    let records = []
    if (typeof indentityIndex === 'string') {
      records = [indentityIndex]
    } else if ($.isArray(indentityIndex)) {
      indentityIndex.forEach(function (idIndex) {
        let record = model.getRecord(_makeIdentityIndex(idIndex))
        if (record) {
          records.push(record)
        }
      })
    }
    if (records.length > 0) {
      grid$.grid('setSelectedRecords', records, false)
    }
  }

  function Binding () {
    this.observers = []
    this.checks = []
  }

  Binding.prototype.subscribe = function (eventName, callback) {
    this.observers[eventName] || (this.observers[eventName] = [])
    this.observers[eventName].push(callback)
  }

  Binding.prototype.notify = function (event) {
    let args = Array.prototype.slice.call(arguments)
    let eventObservers = this.observers[event]
    let self = this
    args.shift()
    if (Array.isArray(eventObservers)) {
      eventObservers.forEach(function (eventObserver) {
        eventObserver.apply(self, args)
      })
    }
  }

  Binding.prototype.check = function (name) {
    let check = this.checks[name]
    let deferred = $.Deferred()
    let self = this

    // Execute checks and remember which checks failed
    let failedChecks = check.subchecks.filter(function (subcheck) {
      let hasPassed = subcheck.fn.apply(self)
      return (hasPassed === false)
    })

    if (failedChecks.length > 0) {
      // If checks failed then reject promise and return error message
      let msg = failedChecks.map(function (check) {
        return check.msgOnError
      })
      this.debug(check.name, msg)
      deferred.reject(check.name, msg)
    } else {
      // If all checks pass then resolve the promise
      deferred.resolve(check.name)
    }

    return deferred.promise()
  }

  Binding.prototype.debug = function (check, msg) {
    apex.debug(check, 'has failed with following reasons')
    msg.forEach(function (line) {
      apex.debug('-', line)
    })
  }

  // The item should be kept dumb about the grid
  function DataBindingItem (itemName, multiSelectionMethod) {
    // Inherit Binding object properties
    Binding.call(this)

    // Own properties
    this.itemName = itemName
    this.item = apex.item(this.itemName)
    this.item$ = $(this.item.node)
    this.ignoreChange = false
    this.changes = false

    // Set way of displaying multiselection
    this.multiSelectionMethod = gMultiSelectionMethods[multiSelectionMethod]

    this.initChange()
  }

  DataBindingItem.prototype = Object.create(Binding.prototype)

  DataBindingItem.prototype.initChange = function () {
    let self = this
    this.item$.on('focus', function () {
      self.changes = true
    })
    this.item$.on('change', function () {
      self.changes = false
      if (self.ignoreChange) {
        return
      }
      self.notify('change', {
        value: self.item.getValue()
      })
    })
  }

  DataBindingItem.prototype.toggleMultiSelection = function (isSingleSelection) {
    if (isSingleSelection) {
      this.multiSelectionMethod.onFalse(this.item.id)
    } else {
      this.multiSelectionMethod.onTrue(this.item.id)
    }
  }

  DataBindingItem.prototype.setValue = function (value, displayValue) {
    this.ignoreChange = true
    this.item.setValue(value, displayValue)
    this.ignoreChange = false
  }

  DataBindingItem.prototype.setDisabled = function (disabled) {
    this.item[ disabled ? 'disable' : 'enable' ]()
    // this.item$.css('cursor', (disabled) ? 'not-allowed' : 'auto')
  }

  DataBindingItem.prototype.showError = function (error) {
    if (error) {
      apex.message.showErrors([{
        message: error,
        location: 'inline',
        pageItem: this.itemName
      }])
    } else {
      apex.message.clearErrors(this.itemName)
    }
  }

  function DataBindingColumn (columnName, grid, isPrimaryKey, disableItem) {
    // Inherit Binding object properties
    Binding.call(this)

    // Own properties
    this.columnName = columnName
    this.grid = grid
    this.isPrimaryKey = isPrimaryKey
    this.columnConfig
    this.columnItem
    this.disableItem = disableItem

    // Information about the active grid row (multiselect is allowed)
    this.selectedRecords = []

    // Add some metadata about the column
    this.setColumnConfig()
    this.setColumnItem()

    // Add checks before performing some functionality
    this.addChecks()

    // for editable grids, init model events
    if (this.grid.model.allowEdit()) {
      this.initModelEvents()
    }
  }

  DataBindingColumn.prototype = Object.create(Binding.prototype)

  DataBindingColumn.prototype.initModelEvents = function () {
    let self = this
    this.grid.model.subscribe({
      onChange: function (type, change) {
        if (type === 'delete') {
          // On delete, make sure binding for the record is removed
          let deletedRecordsInSelection = []
          change.recordIds.forEach(function (recordId) {
            self.selectedRecords.forEach(function (record) {
              if (recordId === self.grid.model.getRecordId(record)) {
                deletedRecordsInSelection.push(recordId)
              }
            })
          })
          if (deletedRecordsInSelection.length > 0) {
            self.notify('delete')
          }
        } else if (type === 'set') {
          // Only change corresponding item if the change was in the currently binded record
          let changedRecordsInSelection = []
          self.selectedRecords.forEach(function (record) {
            if (change.recordId === self.grid.model.getRecordId(record)) {
              changedRecordsInSelection.push(change.recordId)
            }
          })
          if (changedRecordsInSelection.length > 0) {
            self.notify('set')
          }
        } else if (type === 'metaChange') {
          self.notify('metachange')
        } else if (type === 'addData') {
          // Use the addData instead of gridpagechange. This is the best alternative to afterrefresh
          if (change.count === 0) {
            self.notify('noselection')
          }
        }
      }
    })
  }

  DataBindingColumn.prototype.setColumnConfig = function () {
    let columns = this.grid.view$.grid('getColumns')
    let self = this
    this.columnConfig = columns.filter(function (column) {
      return (column.property === self.columnName)
    })[0]
  }

  DataBindingColumn.prototype.setColumnItem = function () {
    this.columnItem = apex.item(this.columnConfig.elementId)
  }

  DataBindingColumn.prototype.singleRecordSelected = function () {
    if (!this.isRecordSelected()) {
      return true
    }
    return this.selectedRecords.length === 1
  }

  DataBindingColumn.prototype.isRecordSelected = function () {
    return this.selectedRecords.length > 0
  }

  DataBindingColumn.prototype.isEditable = function () {
    let self = this
    let editableRecords = this.selectedRecords.filter(function (record) {
      let recordId = self.grid.model.getRecordId(record)
      let recordMetadata = self.grid.model.getRecordMetadata(recordId)

      // Record is editable when you can edit an existing record or when its a new record
      if (self.grid.model.allowEdit(record)) {
        return true
      }
      if (recordMetadata.inserted) {
        return true
      }
      if (recordMetadata.allowedOperations && recordMetadata.allowedOperations.update) {
        return true
      }

      // Seems like record is not editable after checks
      return false
    })

    return editableRecords.length > 0
  }

  DataBindingColumn.prototype.recordIsNotDeleted = function () {
    let self = this
    let deletedRecords = this.selectedRecords.filter(function (record) {
      let recordId = self.grid.model.getRecordId(record)
      return (self.grid.model.getRecordMetadata(recordId).deleted)
    })
    return deletedRecords.length === 0
  }

  DataBindingColumn.prototype.addChecks = function () {
    this.checks['set'] = {
      name: 'Checks to execute before setting the column value',
      subchecks: [
        {
          fn: this.isEditable,
          msgOnError: 'The column for this record is not editable'
        }, {
          fn: this.recordIsNotDeleted,
          msgOnError: 'The record is deleted'
        }/*, {
          fn: this.singleRecordSelected,
          msgOnError: 'Please select a single record'
        }*/
      ]
    }

    this.checks['beforeEditableGet'] = {
      name: 'Checks to execute before getting and passing a column value from an editable grid',
      subchecks: [
        {
          fn: this.recordIsNotDeleted,
          msgOnError: 'The record is deleted'
        }/*, {
          fn: this.singleRecordSelected,
          msgOnError: 'Please select a single record'
        }*/
      ]
    }

    this.checks['beforeNonEditableGet'] = {
      name: 'Checks to execute before getting and passing a column value from a non editable grid',
      subchecks: [
        {
          fn: this.isRecordSelected,
          msgOnError: 'No records selected'
        }
      ]
    }

    this.checks['beforePrimaryKeyGet'] = {
      name: 'Checks to execute before getting and passing a primary key column value from a grid',
      subchecks: [
        {
          fn: this.isRecordSelected,
          msgOnError: 'No records selected'
        }
      ]
    }

    this.checks['getrecord'] = {
      name: 'Checks to execute before getting the active record',
      subchecks: [
        {
          fn: this.isRecordSelected,
          msgOnError: 'No records selected'
        }
      ]
    }
  }

  DataBindingColumn.prototype.setValue = function (value) {
    let self = this
    this.check('set')
      .then(function () {
        // Set columnItem only to get validity
        self.columnItem.setValue(value)
        let validity = self.columnItem.getValidity()

        self.selectedRecords.forEach(function (record) {
          let recordId = self.grid.model.getRecordId(record)

          // Set record value and validity
          self.grid.model.setValue(record, self.columnName, value)
          if (!validity.valid) {
            self.grid.model.setValidity('error', recordId, self.columnName, self.columnItem.getValidationMessage())
          } else {
            self.grid.model.setValidity('valid', recordId, self.columnName)
          }
        })
      })
  }

  DataBindingColumn.prototype.getValue = function () {
    let values = []
    let self = this

    this.selectedRecords.forEach(function (record) {
      let value = self.grid.model.getValue(record, self.columnName)
      values.push(value.v || value)
    })

    if (_allEqual(values)) {
      return values[0]
    } else {
      return ''
    }
  }

  DataBindingColumn.prototype.getSelectedRowsValues = function () {
    let self = this
    let values = []

    this.selectedRecords.forEach(function (record) {
      let recordId = self.grid.model.getRecordId(record)
      if (!self.grid.model.getRecordMetadata(recordId).deleted) {
        let value = self.grid.model.getValue(record, self.columnName)
        values.push(value.v || value)
      }
    })

    if (self.isPrimaryKey) {
      return values.join(':')
    } else {
      if (_allEqual(values)) {
        return values[0]
      } else {
        return ''
      }
    }
  }

  DataBindingColumn.prototype.getError = function () {
    let self = this
    let errors = this.selectedRecords.map(function (record) {
      let recordId = self.grid.model.getRecordId(record)
      let recordMetadata = self.grid.model.getRecordMetadata(recordId)
      if (!recordMetadata.fields) {
        return
      }
      let columnMetadata = recordMetadata.fields[self.columnName]

      if (columnMetadata && columnMetadata.error) {
        return columnMetadata.message
      }
    })
    return errors[0]
  }

  function TwoWayDataBinding (ColumnName, itemName, grid, isPrimaryKey, disableItem, multiSelectionMethod) {
    this.columnBinding = new DataBindingColumn(ColumnName, grid, isPrimaryKey, disableItem)
    this.itemBinding = new DataBindingItem(itemName, multiSelectionMethod)
    this.allowEdit = this.columnBinding.grid.model.allowEdit()

    // Add column observers
    this.columnBinding.subscribe('noselection', $.proxy(this.onNoSelection, this))
    this.columnBinding.subscribe('select', $.proxy(this.onSelectRow, this))

    // Add extra observers for editable grids
    if (this.allowEdit) {
      this.columnBinding.subscribe('metachange', $.proxy(this.onMetaChange, this))
      this.columnBinding.subscribe('delete', $.proxy(this.onDelete, this))
      this.columnBinding.subscribe('set', $.proxy(this.onSetColumn, this))
    }

    // Add item observers for editable grids
    if (this.allowEdit) {
      // not for primary keys
      if (!this.columnBinding.isPrimaryKey) {
        this.itemBinding.subscribe('change', $.proxy(this.onChangeItem, this))
      }
    }
  }

  TwoWayDataBinding.prototype.onMetaChange = function () {
    let self = this
    setTimeout(function () {
      self.itemBinding.showError(self.columnBinding.getError())
    })
  }

  TwoWayDataBinding.prototype.onSetColumn = function () {
    this.itemBinding.setValue(this.columnBinding.getValue())
    this.itemBinding.showError(this.columnBinding.getError())
  }

  TwoWayDataBinding.prototype.onDelete = function () {
    this.itemBinding.setValue('')
    this.itemBinding.setDisabled(true)
  }

  TwoWayDataBinding.prototype.onNoSelection = function () {
    this.itemBinding.setValue('')
    this.itemBinding.setDisabled(true)
  }

  TwoWayDataBinding.prototype.onSelectRow = function (selectedRecords) {
    // Update column Binding
    this.columnBinding.selectedRecords = selectedRecords

    let self = this

    if (this.columnBinding.isPrimaryKey) {
      this.columnBinding.check('beforePrimaryKeyGet')
        .done(function () {
          self.itemBinding.setDisabled(self.columnBinding.disableItem)
          self.itemBinding.toggleMultiSelection(self.columnBinding.singleRecordSelected())
          self.itemBinding.setValue(self.columnBinding.getSelectedRowsValues())
        })
        .fail(function (failedChecks) {
          self.itemBinding.setValue('')
          self.itemBinding.toggleMultiSelection(self.columnBinding.singleRecordSelected())
          self.itemBinding.setDisabled(true)
        })
    } else {
      if (this.allowEdit) {
        // Try to set item, but only if checks on column are passed
        this.columnBinding.check('beforeEditableGet')
          .done(function () {
            self.itemBinding.setDisabled(!self.columnBinding.isEditable())
            self.itemBinding.setValue(self.columnBinding.getSelectedRowsValues())
            self.itemBinding.toggleMultiSelection(self.columnBinding.singleRecordSelected())
            self.itemBinding.showError(self.columnBinding.getError())
          })
          .fail(function (failedChecks) {
            self.itemBinding.setValue('')
            self.itemBinding.toggleMultiSelection(self.columnBinding.singleRecordSelected())
            self.itemBinding.setDisabled(true)
          })
      } else {
        // Non editable grid
        this.columnBinding.check('beforeNonEditableGet')
          .done(function () {
            self.itemBinding.setDisabled(self.columnBinding.disableItem)
            self.itemBinding.toggleMultiSelection(self.columnBinding.singleRecordSelected())
            self.itemBinding.setValue(self.columnBinding.getValue())
          })
      }
    }
  }

  TwoWayDataBinding.prototype.onAddRow = function () {
    this.columnBinding.setValue('')
    this.itemBinding.toggleMultiSelection(this.columnBinding.singleRecordSelected())
    this.itemBinding.showError(this.columnBinding.getError())
  }

  TwoWayDataBinding.prototype.onChangeItem = function (data) {
    this.columnBinding.setValue(data.value)
    this.itemBinding.toggleMultiSelection(this.columnBinding.singleRecordSelected())
    this.itemBinding.showError(this.columnBinding.getError())
  }
  /**
   * When a record is updated in the grid, update a page item and vice versa
   * 1. add observer for model changes -> update page items accordingly
   * 2. add observer for page item changes -> update record accordingly
   *
   * Challenge: How can we be sure that the data in the page items and the grid are about the same row?
   * - You should not use this plugin for multiselect grids
   * - But a row can be deleted even when not selected
   * - Create a data-binding object with: recordID, setItem callback, setColumn Callback.
   * - The trigger is always the row, not the item
   *
   * @param {any} da Dynamic Action
   * @param {any} columns String of columnNames
   * @param {any} pageItems String of pageItem names
   */
  function addDataBinding (options) {
    let promise = _getWidget(options.regionId)

    promise.done(function (ig$) {
      let pkItemNameArr = _stringToArray(options.pkItems)
      let itemNameArr = _stringToArray(options.pageItems)
      let columnNameArr = _stringToArray(options.columns)
      let gridView = ig$.interactiveGrid('getViews').grid
      let gridBindings = []
      // let editableConfig = ig$.interactiveGrid('option', 'config.editable.')
      let autoAddRow = ig$.interactiveGrid('option', 'config.editable.autoAddRow')

      // There must be a grid view
      if (!gridView) {
        return
      }

      // Trigger no recordSelection after model change if needed
      gridView.model.subscribe({
        onChange: function (type, change) {
          if (type === 'addData') {
            if ((change.count === 0) && (!autoAddRow)) {
              gridView.view$.trigger('mho:ig:noselectedrows')
            }
          }
        }
      })

      // Trigger no rows selected
      ig$.on('interactivegridselectionchange', function (e, d) {
        if (d.selectedRecords.length === 0) {
          ig$.trigger('mho:ig:noselectedrows')
        } else {
          ig$.trigger('mho:ig:selectedrows')
        }
      })

      // // Create the binding per primary key column
      if (pkItemNameArr.length > 0) {
        let pkColumns = _getPrimaryKeyColumns(gridView.view$)
        pkItemNameArr.forEach(function (itemName, idx) {
          gridBindings.push(new TwoWayDataBinding(pkColumns[idx], itemName, gridView, true, options.disableItems, options.multiSelectionMethod))
        })
      }

      // Create the binding per column
      itemNameArr.forEach(function (itemName, idx) {
        gridBindings.push(new TwoWayDataBinding(columnNameArr[idx], itemName, gridView, false, options.disableItems, options.multiSelectionMethod))
      })

      // Expose bindings for other functions
      gColumnBindings[options.regionId] = gridBindings
    })
  }

  /**
   * When selecting a IG row, set page items with column values
   * Only works for single row selection because Page Items can have only one value
   *
   * @param {any} options input from APEX plugin
   *  da: dynamic action
   */
  function setRowItems (options) {
    // Do nothing for for singlerecordview
    if (options.da.browserEvent.originalEvent && options.da.browserEvent.originalEvent.type === 'recordviewrecordchange') {
      return
    }

    let gridBindings = gColumnBindings[options.da.triggeringElement.id]
    let selectedRecords = options.da.data.selectedRecords

    gridBindings.forEach(function (binding) {
      // If item has changes, then set column value first
      if (binding.itemBinding.changes) {
        binding.itemBinding.notify('change', {
          value: binding.itemBinding.item.getValue()
        })
        binding.itemBinding.ignoreChange = true
      }

      binding.columnBinding.notify('select', selectedRecords)
    })
  }

  /**
   * On page load, select row based on pk page item
   *
   * Only works for single row selection because Page Items can have only one value
   *
   * @param {any} options input from APEX plugin
   *  da:     dynamic action
   *  pkItem: Primary key column names (position must be same as primary key column order for surrogate PKs)
   */
  function selectRecordWithPkPageItemValue (options) {
    let promise = _getWidget(options.regionId)
    promise.done(function (ig$) {
      let gridView = ig$.interactiveGrid('getViews').grid
      let pkItemNames = _stringToArray(options.pkItem)
      // if no selected record then try to select one and exit this function
      let pkPageItemValues = pkItemNames.map(function (name) {
        return apex.item(name).getValue()
      })
      if (pkPageItemValues) {
        if (pkPageItemValues[0].indexOf(':') > -1) {
          pkPageItemValues = pkPageItemValues[0].split(':')
        }
        _selectRecord(gridView.view$, pkPageItemValues, true)
      }
    })
  }

  // Add functions to namespace
  namespace.IGSetItems = {
    addDataBinding: addDataBinding,
    setRowItems: setRowItems,
    selectRecordWithPkPageItemValue: selectRecordWithPkPageItemValue
  }
})(window.mho)
