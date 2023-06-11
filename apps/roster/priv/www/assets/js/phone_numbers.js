/**
 * Created by ne_luboff on 23.02.18.
 * Manage whitelist and fake numbers data.
 */

// TODO delete unused vars



$(document).ready(function() {
    window.onload = GetWhitelistFromServer("down");

    // API management section

    function GetWhitelistFromServer(order) {
        $.ajax({
            url: GetCurrentUrl(),
            type: 'GET',
            success: function(data) {
                var parsed_data = JSON.parse(data);
                var status = parsed_data["Status"];
                var payload = parsed_data["Data"];
                if (status == "Success" ) {
                    FillWhitelist(payload, order);
                }
            }
        });
    }

    function PutWhitelist(data) {
        $.ajax({
            url: GetCurrentUrl(),
            type: 'PUT',
            data: '{"phone":['+ data + ']}',
            success: function(data) {
                var parsed_data = JSON.parse(data);
                var status = parsed_data["Status"];
                if (status == "Success" ) {
                    document.getElementById('close-modal-window').click();
                    GetWhitelistFromServer("down");
                }
            },
            error: function(data) {
                var status = data["status"];
                if (status == 400 ) {
                    var responseText = data["responseText"];
                    var parsed_data = JSON.parse(responseText);
                    var payload = parsed_data["Reason"];
                    RenderErrorMessageInModal(payload);
                }
            }
        });
    }

    function RemoveFromWhitelist(data) {
        $.ajax({
            url: GetCurrentUrl() + '?' + $.param({'phone': data}, true),
            type: 'DELETE',
            success: function(data) {
                var parsed_data = JSON.parse(data);
                var status = parsed_data["Status"];
                if (status == "Success" ) {
                    GetWhitelistFromServer("down");
                }
            },
            error: function(data) {
                var status = data["status"];
                if (status == 400 ) {
                    console.log(data["responseText"])
                }
            }
        });
    }

    // Helpers section

    function GetCurrentUrl() {
        var URL = '/whitelist';
        if (window.location.pathname == "/fake_numbers" || document.url == "/fake_numbers#") {
            URL = '/fn'
        }
        return URL;
    }

    function FillWhitelist(data, order) {
        data = SortByCreated(data);
        if (order == "down") {
            data = data.reverse();
        }
        var r = new Array(), j = -1;
        for (var key = 0, size = data.length; key < size; key++) {
            r[++j] ='<tr><td class="whitelist_phone">';
            r[++j] = data[key]['phone'];
            r[++j] = '</td><td class="whitelist_created">';
            r[++j] = data[key]['created'];
            r[++j] = '</td><td class="whitelist_action"><label class="checkbox-container">' +
            '<input data-state="unchecked" type="checkbox" data-phone="' + data[key]['phone'] + '">' +
            '<span class="checkmark"></span></label></td>';
        }
        $('#whitelist_table').html(r.join(''));
    }

    function GetDeletionApproval(data) {
        if (confirm('Do you really want to remove next phone number(s) from the list? ' + data.split(',').join(', '))) {
            RemoveFromWhitelist(data)
        }
    }

    function compare(a, b) {
        const valA = a.created;
        const valB = b.created;
        var comparison = 0;
        if (valA > valB) {
            comparison = 1;
        } else if (valA < valB) {
            comparison = -1;
        }
        return comparison;
    }

    function SortByCreated(data) {
        return data.sort(compare);
    }

    function ValidateNumbers(data) {
        if (data) {
            var validation_result = IsPositiveInteger(ReplaceComma(data));
            if (validation_result) {
                PutWhitelist(data)
            } else {
                RenderErrorMessageInModal("Invalid phone numbers format. All numbers should be integer! " +
                "Please, add numbers in format: 1234567890, 1234567891")
            }
        } else {
            RenderErrorMessageInModal("Cannot found phone numbers to add")
        }
    }

    function ReplaceComma(data) {
        return data.replace(/,/g, '');
    }

    function IsPositiveInteger(data) {
        return data > 0 && Number.isInteger(parseFloat(ReplaceComma(data)));
    }

    function RenderErrorMessageInModal(data) {
        var error_data = '<h5 class="modal-title">' + "* Error! " + data + '</h5>';
        $('#whitelist-modal-error').html(error_data);
    }

    function ProceedNumbersToBeDeleted(data) {
        if (data.length == 0) {
            alert("Please, select one or more numbers to delete");
        } else {
            var phones_to_be_deleted = new Array();
            Array.from(data).forEach(function(element) {
                phones_to_be_deleted.push(element.dataset.phone);
            });
            GetDeletionApproval(phones_to_be_deleted.join(","));
        }
    }

    // HTML elements events procession section

    $('#open-modal-dialog-btn').click(function() {
        // clean add numbers modal
        $('#whitelist-modal-error').html("");
        document.getElementById('add_number_input').value = '';
    });

    $('#add_number_submit').click(function() {
        // get numbers to be added
        var new_numbers = $("#add_number_input").val();
        ValidateNumbers(new_numbers);
    });

    $('#whitelist_table').on('click', "input", function() {
        var state = $(this).attr("data-state");
        var new_state = "checked";
        if (state == "checked") {
            new_state = "unchecked"
        }
        $(this).attr("data-state", new_state);
    });

    $('#remove-numbers-btn').click(function() {
        // get numbers to be added
        ProceedNumbersToBeDeleted(document.querySelectorAll('[data-state="checked"]'));
    });

    $('#whitelist_created_column').click(function() {
        // sort list by created date
        var element = document.getElementById('whitelist_created_column');
        var order = element.dataset.order;
        var new_order = "down";
        if (order == "down") {
            new_order = "up"
        }
        element.dataset.order = new_order;
        GetWhitelistFromServer(new_order)
    });
});