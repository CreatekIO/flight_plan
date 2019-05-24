import React, { Component } from "react";
import { connect } from "react-redux";
import { Button, Header, Image, Modal, Form } from "semantic-ui-react";
import { ticketCreated } from "../action_creators";

class AddNewIssueForm extends Component {
    state = {
        title: "",
        description: ""
    };

    handleChange = (e, { name, value }) => {
        this.setState({ [name]: value });
    };

    handleSubmit = () => {
        ticketCreated(this.state);
    };

    render() {
        return (
            <Form onSubmit={this.handleSubmit}>
                <Form.Input
                    label={"Title"}
                    placeholder={"Issue title"}
                    name="title"
                    onChange={this.handleChange}
                />
                <Form.TextArea
                    label={"Description"}
                    placeholder={"Issue description"}
                    name="description"
                    onChange={this.handleChange}
                />
                <Form.Button>Submit</Form.Button>
            </Form>
        );
    }
}

const AddNewIssueModal = () => (
    <Modal id={"add-new-issue-modal"} trigger={<a className="item">Add an issue</a>}>
        <Modal.Header>Add a new issue</Modal.Header>
        <Modal.Content>
            <AddNewIssueForm />
        </Modal.Content>
    </Modal>
);

export default AddNewIssueModal;
