import React, { Component } from 'react';
import { Button, Header, Image, Modal, Form } from 'semantic-ui-react';

const IssueModal = () => (
    <Modal
        id={'add-new-issue-modal'}
        trigger={<a className="item">Add an issue</a>}>
        <Modal.Header>Add a new issue</Modal.Header>
        <Modal.Content>
            <AddNewIssueForm />
        </Modal.Content>
    </Modal>
);

class AddNewIssueForm extends Component {
    state = {
        title: '',
        description: '',
        submittedTitle: '',
        submittedDescription: ''
    };

    handleChange = (e, { name, value }) => {
        this.setState({ [name]: value });
    };

    handleSubmit = () => {
        const { title, description } = this.state;

        this.setState({
            submittedTitle: title,
            submittedDescription: description
        });
    };

    render() {
        return (
            <Form onSubmit={this.handleSubmit}>
                <Form.Input
                    label={'Title'}
                    placeholder={'Issue title'}
                    name="title"
                    onChange={this.handleChange}
                />
                <Form.TextArea
                    label={'Description'}
                    placeholder={'Issue description'}
                    name="description"
                    onChange={this.handleChange}
                />
                <Form.Button>Submit</Form.Button>
            </Form>
        );
    }
}

export default IssueModal;
